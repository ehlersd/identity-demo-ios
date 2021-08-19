//
//  ViewController+Helper.swift
//  CIAMSDK
//
//  Created by Mallikarjuna Punuru on 09/07/21.
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

import Foundation
import UIKit

extension UIViewController {
    class func loadFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>() -> T {
            let frameworkBundleID  = "com.cyberark.Identity"
            let bundle = Bundle(identifier: frameworkBundleID)
            return T.init(nibName: String(describing: T.self), bundle: bundle)
        }

        return instantiateFromNib()
    }
}
extension UIViewController {
   public func showAlert(with title: String? = "", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    static func showAlertOnRootView(with presenter: UIViewController? = UIApplication.shared.windows.last?.rootViewController,
                                    title: String? = "",
                                    message: String) {
        DispatchQueue.main.async {
            presenter?.showAlert(with: title, message: message)
        }
     }
}

