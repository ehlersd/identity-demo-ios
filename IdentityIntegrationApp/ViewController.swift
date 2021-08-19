//
//  ViewController.swift
//  IdentitySDKIntegrationExample
//
//  Created by Mallikarjuna Punuru on 07/07/21.
//
/* Copyright (c) 2021 CyberArk Software Ltd. All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit
import Identity

class ViewController: UIViewController {
    let scannerBuilder = QRAuthenticationProvider()
    
    let homeViewSegueIdentifier = "HomeViewSegueIdentifier"
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    var loginTypes = [
        "Login"
        //"Refresh Token",
        //"End Session/Logout"
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        //addQRAuth()
        registerCell()
        addObserver()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    @IBAction func login_click(_ sender: Any) {
        navigateToLogin()
    }
    func addQRAuth() {
        do  {
            if let _ = try KeyChainWrapper.standard.fetch(key: "access_token")?.toString() {
                if !loginTypes.contains("QRCode Authenticator") {
                    loginTypes.append("QRCode Authenticator")
                }
            } else {
                loginTypes = loginTypes.filter { $0 != "QRCode Authenticator" }
            }
            self.tableView.reloadData()
        } catch {
            
        }
    }
    func registerCell() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        loginTypes.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = loginTypes[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigate(index: indexPath.row)
    }
}
//MARK: Weblogin
extension ViewController {
    func navigate(index: Int) {
        if index == 0 {
            navigateToLogin()
        }  else if index == 1 {
            refreshToken()
        }else if index == 2 {
            closeSession()
        }else {
            navigateToScanner()
        }
    }
    
    /// Launches the extrenal safari view controller based on the configuration
    /// Setup the initial configuration
    /// Custom browser Parameters
    ///
    func navigateToLogin() {
        
        guard let config = plistValues(bundle: Bundle.main) else { return }
        
        guard let account =  CyberArkAuthProvider.webAuth()?
                .set(clientId: config.clientId)
                .set(domain: config.domain)
                .set(redirectUri: config.redirectUri)
                .set(applicationID: config.applicationID)
                .set(presentingViewController: self)
                .setCustomParam(key: "", value: "")
                .set(scope: config.scope)
                .set(webType: .sfsafari)
                .build() else { return }
        CyberArkAuthProvider.login(account: account)
            
    }
    
    func addObserver(){
        CyberArkAuthProvider.viewmodel()?.didReceiveAccessToken = { (result, accessToken) in
            if result {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        //self.showAlert(with :"Access Token: ", message: accessToken)
                        self.navigateToHomeScreen()
                        //self.addQRAuth()
                    }
                }
            }
        }
    }
    func closeSession() {
        guard let config = plistValues(bundle: Bundle.main) else { return }
        
        guard let account =  CyberArkAuthProvider.webAuth()?
                .set(clientId: config.clientId)
                .set(domain: config.domain)
                .set(redirectUri: config.redirectUri)
                .set(applicationID: config.applicationID)
                .set(presentingViewController: self)
                .setCustomParam(key: "", value: "")
                .set(webType: .sfsafari)
                .build() else { return }
        CyberArkAuthProvider.closeSession(account: account)
        
    }
    func refreshToken() {
        CyberArkAuthProvider.sendRefreshToken()
    }
    
   
}
//MARK: QRScanner
extension ViewController {
    func navigateToScanner() {
        //let value = "https://aaj7479.my.dev.idaptive.app/security/StartQRCodeAuthentication?guid=LSTcJk-da06TYEDDJbnjS-nIRy7cUvIUWmfIyExGcoo1"
//        scannerBuilder.authenticate(qrCode: nil, presenter: self)
    }
}
extension ViewController {
    func navigateToHomeScreen() {
        performSegue(withIdentifier: homeViewSegueIdentifier, sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == homeViewSegueIdentifier) {
            _ = segue.destination as! HomeViewController
        }
    }
}
extension ViewController {
    func plistValues(bundle: Bundle) -> (clientId: String, domain: String, domain_auth0: String, scope: String, redirectUri: String, threshold: Int, applicationID: String, logouturi: String)? {
        guard
            let path = bundle.path(forResource: "IdentityConfiguration", ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing CIAMConfiguration.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }
        guard
            let clientId = values["clientid"] as? String,
            let domain = values["domainautho"] as? String, let scope = values["scope"] as? String, let redirectUri = values["redirecturi"] as? String, let threshold = values["threshold"] as? Int, let applicationID = values["applicationid"] as? String, let logouturi = values["logouturi"] as? String
        else {
            print("IdentityConfiguration.plist file at \(path) is missing 'ClientId' and/or 'Domain' values!")
            return nil
        }
        return (clientId: clientId, domain: domain, domain_auth0: domain, scope: scope, redirectUri: redirectUri, threshold: threshold, applicationID: applicationID, logouturi: logouturi)
    }
}
