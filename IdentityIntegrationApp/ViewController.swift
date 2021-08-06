//
//  ViewController.swift
//  IdentitySDKIntegrationExample
//
//  Created by Mallikarjuna Punuru on 07/07/21.
//

import UIKit
import Identity

class ViewController: UIViewController {
    let scannerBuilder = QRCodeReaderBuilder()
    
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
        //addQRAuth()
//        BiometricsAuthenticator().authenticateUser { (response) in
//            switch response {
//            case .success(let success):
//                print("Success \(success)")
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    print("Error for Biometric enrole\(error.localizedDescription)")
//                    let mesage = error.localizedDescription
//                    let alertController = UIAlertController(title: "BioMetric Error", message: mesage, preferredStyle: .alert)
//                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
//                    alertController.addAction(action)
//                    self.present(alertController, animated: true, completion: nil)
//                }
//            }
//        }
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
        guard let _ = plistValues(bundle: Bundle.main) else { return }
        CyberArkAuthProvider.webAuth()?
            .set(presentingViewController: self)
            .setCustomParam(key: "", value: "")
            .set(webType: .sfsafari)
            .build()
            .login(completion: { (result, error) in
                if((result) != nil) {
                    
                }
            })
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
        guard let _ = plistValues(bundle: Bundle.main) else { return }
        CyberArkAuthProvider.webAuth()?.set(presentingViewController: self)
            .setCustomParam(key: "", value: "")
            .build()
            .closeSession(completion: { (result, error) in
                if((result) != nil) {
                    self.addQRAuth()
                }
            })
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
            let controller = segue.destination as! HomeViewController
        }
    }
}
//MARK:- read from plist
extension ViewController {
    func plistValues(bundle: Bundle) -> (clientId: String, domain: String, domain_auth0: String)? {
        guard
            let path = bundle.path(forResource: "IdentityConfiguration", ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing CIAMConfiguration.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }
        guard
            let clientId = values["clientid"] as? String,
            let domain = values["domainautho"] as? String, let scope = values["scope"] as? String, let redirectUri = values["redirecturi"] as? String,let applicationID = values["applicationid"] as? String, let threshold = values["threshold"] as? Int
        else {
            print("IdentityConfiguration.plist file at \(path) is missing 'ClientId' and/or 'Domain' values!")
            return nil
        }
        return (clientId: clientId, domain: domain, domain_auth0:domain)
    }

}
