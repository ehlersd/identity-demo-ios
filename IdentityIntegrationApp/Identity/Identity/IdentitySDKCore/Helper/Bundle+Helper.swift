//
//  Bundle+Helper.swift
//  CIAMSDK
//
//  Created by Mallikarjuna Punuru on 05/07/21.
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

let CFBundleVersion = "CFBundleVersion"
let CFBundleShortVersionString = "CFBundleShortVersionString"
let CFBundleDisplayName = "CFBundleDisplayName"

extension Bundle {
    static func getVersion() -> String? {
        return Bundle.main.infoDictionary?[CFBundleVersion] as? String ?? "1.0"
    }
    static func getBuildNumber() -> String? {
        return Bundle.main.infoDictionary?[CFBundleShortVersionString] as? String ?? "1.0"
    }
    static func getBundleIdentifier() -> String? {
        return Bundle.main.bundleIdentifier
    }
    static func getdisplayName() -> String? {
        return Bundle.main.infoDictionary?[CFBundleDisplayName] as? String
    }
}
