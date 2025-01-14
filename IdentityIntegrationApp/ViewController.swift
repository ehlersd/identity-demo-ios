
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


enum LoginType: Int {
    case cyberarkhostedlogin
    case stepupauthenticationusingMFA
    case authenticationWidget

    var index: Int {
        return rawValue
    }
    var value: String {
        switch self {
        case .cyberarkhostedlogin:
            return "CyberArk Hosted Login"
        case .stepupauthenticationusingMFA:
            return "Step-up authentication using MFA widget"
        case .authenticationWidget:
            return "Authentication Widgets"
        }
    }
}

class ViewController: UIViewController {
    
    //Segue identifiers
    let homeViewSegueIdentifier = "HomeViewSegueIdentifier"
    let settingsViewSegueIdentifier = "SettingsSugueidentifier"
    let nativeLoginSegueIdentifier = "NativeLoginSegueIdentifier"
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    var loginTypes: [LoginType] = [.cyberarkhostedlogin, .stepupauthenticationusingMFA, .authenticationWidget]
    
    func updateSections() {
        // When some kind of state changes, rebuild `sections` to include the relevant sections
    }
    
}
//MARK:- View life cycle
extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeBlurrView()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBlurrView()
    }
    @IBAction func login_click(_ sender: Any) {
        doLogin()
    }
}
//MARK:- Initial configuration
extension ViewController {
    func configure(){
        registerCell()
        addObserver()
        addLogoutObserver()
        addRightBar()
        addAuthWidgetResourceURLObserver()
    }
    func registerCell() {
        /*let logo = UIImage(named: "acme_logo")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView*/
        self.navigationItem.title = "Acme Inc"
        let backButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = backButton
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension;
        tableView.allowsSelection = true
        tableView.register(UINib(nibName: "LoginTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "LoginTypeTableViewCell")
    }
    @objc func back()  {
        pop()
    }
    func addRightBar() {
        let image = UIImage(named: "settings_icon")?.withRenderingMode(.alwaysOriginal)
        let rightButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rightButtonAction(sender:)))
        rightButtonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem = rightButtonItem
    }
    @objc func rightButtonAction(sender: UIBarButtonItem){
        navigateToSettingsScreen()
    }
    func navigate(type: LoginType) {
        if type == .cyberarkhostedlogin {
            doLogin()
        } else if type == .authenticationWidget {
            launchAuthenticationWidget()
        }else {
            doNativeLogin()
        }
    }
    @objc func navigateToMore(sender: UIButton){
        let type = loginTypes[sender.tag]
        if type == .cyberarkhostedlogin {
            showCyberArkHostedLoginAlert(type: .success, actionType: .defaultCase, title: "", message: "")
        } else if type == .authenticationWidget {
            showAuthenticationWidgetAlert(type: .success, actionType: .defaultCase, title: "", message: "")
        } else {
            showNativeLoginAlert(type: .success, actionType: .defaultCase, title: "", message: "")
        }

    }
    @objc func navigateTo(sender: UIButton) {
        let type = loginTypes[sender.tag]
        navigate(type: type)
    }
}
//MARK:- UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        loginTypes.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: LoginTypeTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LoginTypeTableViewCell", for: indexPath) as! LoginTypeTableViewCell
        cell.selectionStyle = .none
        let type = loginTypes[indexPath.row]
        cell.title_label.text = type.value
        cell.more_button.tag = type.index
        cell.login_button.tag = type.index
        cell.more_button.addTarget(self, action:#selector(navigateToMore), for: .touchUpInside)
        cell.login_button.addTarget(self, action:#selector(navigateTo), for: .touchUpInside)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = loginTypes[indexPath.row]
        navigate(type: type)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
//MARK: Weblogin
extension ViewController {
    /*
    /// Invokes the Login
    /// Launches the extrenal safari view controller based on the configuration
    /// Setup the initial tenant configuration required
    /// setup Custom browser Parameters
    ///
    */
    func doLogin() {
        if Reachability.isConnectedToNetwork() {
            guard let config = plistValues(bundle: Bundle.main, plistFileName: "IdentityConfiguration") else { return }
            //CyberarkAccount
            guard let account =  CyberArkAuthProvider.webAuth()?
                    .set(clientId: config.clientId)
                    .set(domain: config.domain)
                    .set(redirectUri: config.redirectUri)
                    .set(applicationID: config.applicationID)
                    .set(presentingViewController: self)
                    .setCustomParam(key: "", value: "")
                    .set(scope: config.scope)
                    .set(webType: .sfsafari)
                    .set(systemURL: config.systemurl)
                    .build() else { return }

            CyberArkAuthProvider.login(account: account)
        } else {
            showAlert(with: "Network issue", message: "Please connect to the the internet")
        }
       
    }
    /*
    ///
    /// Observer to get the access token
    /// Must call this method before calling the login api
    */
    func addObserver(){
        CyberArkAuthProvider.didReceiveAccessToken = { (status, message, response) in
            if status {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.save(response: response)
                        self.navigateToHomeScreen()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.showAlert(message: message)
                    }
                }
            }
        }
    }
    
    /// To save the data in the keychain
    /// - Parameter response: token response
    func save(response: AccessToken?) {
        do {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isSessionCreated.rawValue)

            if let accessToken = response?.access_token {
                try KeyChainWrapper.standard.save(key: KeyChainStorageKeys.accessToken.rawValue, data: accessToken.toData() ?? Data())
            }
            if let refreshToken = response?.refresh_token {
                try KeyChainWrapper.standard.save(key: KeyChainStorageKeys.refreshToken.rawValue, data: refreshToken.toData() ?? Data())
            }
            if let expiresIn = response?.expires_in {
                let date = Date().epirationDate(with: expiresIn)
                try KeyChainWrapper.standard.save(key: KeyChainStorageKeys.access_token_expiresIn.rawValue, data: Data.init(from: date))
            }
        } catch {
            print("Unexpected error: \(error)")
        }
        
    }
}
//MARK: add Logout Observer
extension ViewController {
    // To get the logout response
    func addLogoutObserver(){
        CyberArkAuthProvider.didReceiveLogoutResponse = { (result, message) in
            if result {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                    }
                }
            }
        }
    }
}
//MARK:- Navigate To Home Screen
extension ViewController {
    func navigateToHomeScreen() {
        performSegue(withIdentifier: homeViewSegueIdentifier, sender: self)
    }
    func navigateToSettingsScreen() {
        performSegue(withIdentifier: settingsViewSegueIdentifier, sender: self)
    }
    func doNativeLogin(){
        performSegue(withIdentifier: nativeLoginSegueIdentifier, sender: self)
    }
    func showCyberArkHostedLoginAlert(type: PopUpType, actionType: PopUpActionType, title: String, message: String, onCompletion: (() -> Void)? = nil) {
        let alertViewController: CustomPopUpViewController =  CustomPopUpViewController.initFromNib()
        
        let normalText = "CyberArk Hosted Login​\n​\nIn this scenario the Acme Inc wants to use the MFA provided by CyberArk Identity by authenticating the users with the CyberArk Identity login.​\n​\nThe user will be redirected to the CyberArk Identity Login page and prompted to enter username and the corresponding MFA factors. On successful authentication an access token will be returned for the user​\n​\nPlease visit here for details on implementation.​\n\n"
        
        let attributedString = normalText.getLinkAttributes(header: "CyberArk Hosted Login​", linkAttribute: "here", headerFont: UIFont.boldSystemFont(ofSize: 22.0), textFont:UIFont.boldSystemFont(ofSize: 15.0), color: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), underLineColor: .white, linkValue: "https://identity-developer.cyberark.com/docs/cyberark-identity-sdk-for-ios")
        
        alertViewController.callCompletion {
            if (onCompletion != nil) {
                onCompletion!()
            }
            alertViewController.dismiss()
        }
        alertViewController.continueCallCompletion {
            if (onCompletion != nil) {
                onCompletion!()
            }
            alertViewController.dismiss {
                self.doLogin()
            }
        }
        
        alertViewController.popUpType = type
        alertViewController.meessageAtributedText = attributedString
        presentTranslucent(alertViewController, modalTransitionStyle: .crossDissolve, animated: true, completion: nil)
    }
    func showNativeLoginAlert(type: PopUpType, actionType: PopUpActionType, title: String, message: String, onCompletion: (() -> Void)? = nil) {
        let alertViewController: CustomPopUpViewController =  CustomPopUpViewController.initFromNib()
        
        let normalText = "Step-up authentication using MFA widget\n​\nIn this scenario Acme Inc wants to provide step-up authentication to end user when the user tries to do funds transfer.\n​\nTo satisfy this scenario Acme Inc uses the CyberArk Identity MFA widget and embeds the widget into the Acme mobile app using the CyberArk Identity mobile SDK.\n​\nPlease visit here for details on implementation."
        
        let attributedString = normalText.getLinkAttributes(header: "Step-up authentication using MFA widget​", linkAttribute: "here", headerFont: UIFont.boldSystemFont(ofSize: 22.0), textFont:UIFont.boldSystemFont(ofSize: 15.0), color: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), underLineColor: .white, linkValue: "https://identity-developer.cyberark.com/docs/cyberark-identity-sdk-for-ios")
        
        alertViewController.callCompletion {
            if (onCompletion != nil) {
                onCompletion!()
            }
            alertViewController.dismiss()
        }
        alertViewController.continueCallCompletion {
            if (onCompletion != nil) {
                onCompletion!()
            }
            alertViewController.dismiss {
                self.doNativeLogin()
            }
        }
        
        alertViewController.popUpType = type
        alertViewController.meessageAtributedText = attributedString
        presentTranslucent(alertViewController, modalTransitionStyle: .crossDissolve, animated: true, completion: nil)
    }
    func showAuthenticationWidgetAlert(type: PopUpType, actionType: PopUpActionType, title: String, message: String, onCompletion: (() -> Void)? = nil) {
        let alertViewController: CustomPopUpViewController =  CustomPopUpViewController.initFromNib()
        
        let normalText = "Authentication Widgets\n​\nThe admin of Acme Inc. creates the authentication widget on the CyberArk Identity portal and uses the page URL to embed the widget into the mobile app. The widget adds sign up and sign in capabilities to your website or mobile app.\n\nEnd-users who sign up are added to the CyberArk Cloud Directory. You can leverage CyberArk Identity\'s authentication and authorization features to secure their accounts. Once the end-user signs up, they are re-directed to the sign in form in the widget to securely sign in using multi-factor authentication.\n\nThe same widget prompts end-users to authenticate to your website with MFA. The widget can be integrated with sign in protocols such as OIDC/SAML to authorize a user."
        
        let attributedString = normalText.getLinkAttributes(header: "Authentication Widgets​", linkAttribute: "here", headerFont: UIFont.boldSystemFont(ofSize: 22.0), textFont:UIFont.boldSystemFont(ofSize: 15.0), color: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), underLineColor: .white, linkValue: "https://identity-developer.cyberark.com/docs/cyberark-identity-sdk-for-ios")
        
        alertViewController.callCompletion {
            if (onCompletion != nil) {
                onCompletion!()
            }
            alertViewController.dismiss()
        }
        alertViewController.continueCallCompletion {
            if (onCompletion != nil) {
                onCompletion!()
            }
            alertViewController.dismiss {
                self.launchAuthenticationWidget()
            }
        }
        
        alertViewController.popUpType = type
        alertViewController.meessageAtributedText = attributedString
        presentTranslucent(alertViewController, modalTransitionStyle: .crossDissolve, animated: true, completion: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == homeViewSegueIdentifier) {
            let controller = segue.destination as! HomeViewController
            controller.isFromLogin = true
        } else if (segue.identifier == settingsViewSegueIdentifier) {
            _ = segue.destination as! SettingsViewController
        }else if (segue.identifier == nativeLoginSegueIdentifier) {
            let controller = segue.destination as! LoginViewController
            controller.loginType = .authenticationWidget
        }
    }
  
}
extension ViewController {
    func showAlert(message: String){
        
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.closeSession()
        })
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
extension ViewController {
    
    /// To close the current session
    /// Remove  all the data which is persisted locally
    func closeSession() {
        removePersistantStorage()
        guard let config = plistValues(bundle: Bundle.main, plistFileName: "IdentityConfiguration") else { return }
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
    func removePersistantStorage() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isBiometricOnAppLaunchEnabled.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isBiometricWhenAccessTokenExpiresEnabled.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isBiometricOnQRLaunch.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isSessionCreated.rawValue)
    }
}
extension UIViewController {
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var sceneDelegate: SceneDelegate? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate else { return nil }
        return delegate
    }
    var window: UIWindow? {
        if #available(iOS 13, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return nil }
            return window
        }
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window else { return nil }
        return window
    }
    func addBlurrView() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
    }
    /// Remove UIBlurEffect from UIView
    func removeBlurrView() {
        let blurredEffectViews = self.view.subviews.filter{$0 is UIVisualEffectView}
        blurredEffectViews.forEach{ blurView in
            blurView.removeFromSuperview()
        }
    }
    
}
//MARK: Weblogin
extension ViewController {
    /*
    /// Invokes the Login
    /// Launches the extrenal safari view controller based on the configuration
    /// Setup the initial tenant configuration required
    /// setup Custom browser Parameters
    ///
    */
    func launchAuthenticationWidget() {
        if Reachability.isConnectedToNetwork() {
            guard let config = plistValues(bundle: Bundle.main, plistFileName: "IdentityConfiguration") else { return }
            //CyberarkAccount
            guard let account =  CyberArkAuthProvider.webAuth()?
                    .set(clientId: config.clientId)
                    .set(domain: config.domain)
                    .set(redirectUri: config.redirectUri)
                    .set(applicationID: config.applicationID)
                    .set(presentingViewController: self)
                    .setCustomParam(key: "", value: "")
                    .set(scope: config.scope)
                    .set(webType: .sfsafari)
                    .set(systemURL: config.systemurl)
                    .set(authWidgetHostURL: config.authwidgethosturl)
                    .set(authWidgetID: config.authwidgetId)
                    .set(authWidgetResourceURL: config.authwidgetresourceURL)
                    .build() else { return }

            CyberArkAuthProvider.launchAuthWidget(account: account)
        } else {
            showAlert(with: "Network issue", message: "Please connect to the the internet")
        }
       
    }
    /*
    ///
    /// Observer to get the access token
    /// Must call this method before calling the login api
    */
    func addAuthWidgetResourceURLObserver(){
        CyberArkAuthProvider.didReceiveResurceURLCallback = { (status, message) in
            if status {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.doLogin()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.showAlert(message: message)
                    }
                }
            }
        }
    }
}
extension CaseIterable where Self: Equatable {

    var index: Self.AllCases.Index? {
        return Self.allCases.index { self == $0 }
    }
}
