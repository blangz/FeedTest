//
//  LoginViewController.swift
//  FBFeed
//
//  Created by Touch9003 on 28/4/2563 BE.
//  Copyright © 2563 Touch9003. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    //FB
    let loginManager = LoginManager()
    
    //data
    var feedArray: Array<Any> = []
    var paging: [String:Any] = [:]
    var fbToken = ""
    
    //object
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var loadMoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginButton.addTarget(self, action: #selector(self.login(sender:)), for: .touchUpInside)
        
        self.loadMoreButton.addTarget(self, action: #selector(self.next(sender:)), for: .touchUpInside)
        self.loadMoreButton.isHidden = true
        
        self.tableView.isHidden = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    @IBAction func login(sender: UIButton) {
        DispatchQueue.main.async {
            self.loginManager.logOut()
            
            self.loginManager.logIn(permissions: ["public_profile", "email", "user_posts", "user_photos"], from: self) { (loginResult, error) in
                
                if let error = error { return }
                guard let result = loginResult else { return }
                
                if result.isCancelled { return } else {
                    self.requestFBGraph(token: loginResult?.token)
                }
            }
        }
    }
    
    func requestFBGraph(token: AccessToken?) {
        let params = ["access_token" : token?.tokenString]
        self.fbToken = token?.tokenString ?? ""
        
        let request = GraphRequest.init(graphPath: "/me/posts/", parameters: params as [String : Any], tokenString: token?.tokenString, version: Settings.defaultGraphAPIVersion, httpMethod: .get)
        
        request.start { (connection, result, error) in
            if let res = result {
                let responseDictionary = res as! [String:Any]
                print(responseDictionary)
                
                self.feedArray = responseDictionary["data"] as? Array<Any> ?? []
                self.paging = responseDictionary["paging"] as! [String:Any]
                
                self.loginButton.isEnabled = false
                self.loginButton.setTitle("Logged In", for: .normal)
                
                let next = self.paging["next"] as? String ?? ""
                self.loadMoreButton.isHidden = next.isEmpty ? true : false
                
                self.tableView.isHidden = false
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func next(sender: UIButton) {
        let next = self.paging["next"] as? String ?? ""
        let pageDict = Utility.dictionary(withQuery: next)
        let request = GraphRequest.init(graphPath: "/me/posts/", parameters: pageDict, tokenString: self.fbToken, version: Settings.defaultGraphAPIVersion, httpMethod: .get)
        
        request.start { (connection, result, error) in
            if let res = result {
                let responseDictionary = res as! [String:Any]
                let tempArray = responseDictionary["data"] as? Array<Any> ?? []
                
                for item in tempArray {
                    self.feedArray.append(item)
                }
                
                
                self.paging = responseDictionary["paging"] as! [String:Any]
                
                self.tableView.reloadData()
                
            }
        }
    }
}


//tableview

class FeedTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
}

extension LoginViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.feedArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cells", for: indexPath as IndexPath) as! FeedTableViewCell
        let cellData = self.feedArray[indexPath.row] as! [String:Any]
        
        cell.titleLabel.text = cellData["message"] as? String
        cell.idLabel.text = cellData["id"] as? String
        cell.dateLabel.text = cellData["created_time"] as? String
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
}


