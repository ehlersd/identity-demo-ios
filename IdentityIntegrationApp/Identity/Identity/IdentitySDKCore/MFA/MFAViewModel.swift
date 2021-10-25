//
//  MFAViewModel.swift
//  Identity
//
//  Created by Mallikarjuna Punuru on 13/10/21.
//

import Foundation
/*
/// EnrollmentViewModelProtocol
/// Responsible for the api client and all the data related operations
/// Viewmodel protocol
 */
internal protocol MFAViewModelProtocol {
    /// Completion block which will notify when the mfa response api is finished loading
    /// To get the mfa response
    /// - Parameters:
    ///   - Bool: result
    ///   - String: error or success message
    var didReceiveMFAApiResponse: ((Bool,String) -> Void)? { get set }
    
    /// To handleMFA device
    /// - Parameter baseURL: baseURL
    func handleMFA(baseURL: String)
}
/*
/// AuthenticationViewModel
/// Responsible for the api client and all the data related operations
///
 */
 internal class MFAViewModel {
    
    /// EnrollmentClientProtocol
    private let client : MFAChallengeClientProtocol
    
    /// Callback when enrollment is done
    var didReceiveMFAApiResponse: ((Bool, String) -> Void)?

    ///EnrollResponse
    var enrollResponse: EnrollResponse? {
        didSet {
            self.didReceiveMFAApiResponse!(true, "")
        }
    }
    
    /// Initializer
    /// - Parameter apiClient: apiClient
    init(apiClient: MFAChallengeClientProtocol = MFAChallengeClient()) {
        self.client = apiClient
    }
}
//MARK:- AuthenticationViewModelProtocol implementation
//MARK:- Enroll the device
extension MFAViewModel: MFAViewModelProtocol {
    
    /// Enroll
    /// - Parameter baseURL: baseURL
    internal func handleMFA(baseURL: String) {
        do {
            guard let data = try KeyChainWrapper.standard.fetch(key: KeyChainStorageKeys.accessToken.rawValue), let accessToken = data.toString() else {
                return
            }
            client.handleMFAChallenge(from: true, accesstoken: accessToken, baseURL: baseURL) { [weak self] result in
                switch result {
                case .success(let loginFeedResult):
                    guard let response = loginFeedResult else {
                        self?.didReceiveMFAApiResponse!(false, "unable to enroll the device")
                        return
                    }
                    UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isDeviceEnrolled.rawValue)
                    self?.enrollResponse = response
                case .failure(let error):
                    self?.didReceiveMFAApiResponse!(false, "unable to enroll the device")
                    print("the error \(error)")
                }
            }
        } catch {
            print("Unexpected error: \(error)")
        }
        
    }
}

