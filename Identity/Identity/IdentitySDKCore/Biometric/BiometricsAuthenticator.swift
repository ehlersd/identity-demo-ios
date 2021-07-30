//
//  BiometricsAuthenticator.swift
//  Identity
//
//  Created by Raviraju Vysyaraju on 27/07/21.
//

import Foundation
import LocalAuthentication


public protocol LAContextProtocol {
    func canEvaluatePolicy(_ : LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void)
}

public enum BiometricError: LocalizedError {
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case unknown
    
    public var errorDescription: String {
        switch self {
        case .authenticationFailed: return "There was a problem verifying your identity."
        case .userCancel: return "You pressed cancel."
        case .userFallback: return "You pressed password."
        case .biometryNotAvailable: return "Face ID/Touch ID is not available."
        case .biometryNotEnrolled: return "Face ID/Touch ID is not set up."
        case .biometryLockout: return "Face ID/Touch ID is locked."
        case .unknown: return "Face ID/Touch ID may not be configured"
        }
    }
}

final public class BiometricsAuthenticator {
    let context: LAContextProtocol
    private let policy: LAPolicy
    private let localizedReason: String
    
    private var error: NSError?
    
    public init(context: LAContextProtocol = LAContext(),
                policy: LAPolicy = .deviceOwnerAuthentication,
                localizedReason: String = "Verify your Identity") {
        self.context = context
        self.policy = policy
        self.localizedReason = localizedReason
    }
    
    public func canEvaluatePolicy() -> Bool {
        return context.canEvaluatePolicy(self.policy, error: nil)
    }
    
    public func authenticateUser(completion: @escaping (Result<Bool, BiometricError>) -> Void) {
        guard canEvaluatePolicy() else {
            completion( .failure(BiometricError.biometryNotEnrolled))
            return
        }
        
        let reason = "Identify yourself to continue"
        context.evaluatePolicy(self.policy, localizedReason: reason) { [weak self] (success, evaluateError) in
            if success {
                // User authenticated successfully
                print("Success")
                DispatchQueue.main.async {
                    completion(.success(success))
                }
                
            } else {
                // User authenticated failed
                guard let error = evaluateError else {
                    completion( .failure(BiometricError.unknown))
                    return
                }
                completion(.failure(self?.biometricError(from: error) ?? BiometricError.unknown))
            }
        }
    }
    
    private func biometricError(from laError: Error) -> BiometricError {
        let error: BiometricError
        
        switch laError {
        case LAError.authenticationFailed:
            error = .authenticationFailed
        case LAError.userCancel:
            error = .userCancel
        case LAError.userFallback:
            error = .userFallback
        case LAError.biometryNotAvailable:
            error = .biometryNotAvailable
        case LAError.biometryNotEnrolled:
            error = .biometryNotEnrolled
        case LAError.biometryLockout:
            error = .biometryLockout
        default:
            error = .unknown
        }
        
        return error
    }
}

extension LAContext: LAContextProtocol{
    
}