
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
/*
/// APIClient
/// This protocol is responsible to execute a Request
/// by calling the underlyning layer i.e. URLSession
/// As output for a Request it should provide a Response.
*/
protocol APIClient {
    
    var session: URLSession { get }
    
    func fetch<T: Codable>(with request: URLRequest, decode: @escaping (Codable) -> T?, completion: @escaping (Result<T, APIError>) -> Void)
}
extension APIClient {
    
    /// number of seconds
    var connectionTimout: Float {
        get { return 60.0 }
    }
    /// JSONTaskCompletionHandler
    typealias JSONTaskCompletionHandler = (Codable?, APIError?) -> Void
    
    /// To make the a request along with the decoder with the given data
    ///
    /// - Parameters:
    ///   - request: URLRequest
    ///   - decodingType: decoding type
    ///   - completion: check JSONTaskCompletionHandler
    /// - Returns: URLSessionDataTask
    fileprivate func decodingTask<T: Codable>(with request: URLRequest, decodingType: T.Type, completionHandler completion: @escaping JSONTaskCompletionHandler) -> URLSessionDataTask {
        
        let task =  URLSession.shared.dataTask(with: request) { ( data,response, error) in
            

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, .requestFailed)
                return
            }
            debugPrint("httpResponse: \(httpResponse.debugDescription) \(response)")

            if httpResponse.status! == .ok {
                if let data = data {
                    do {
                        debugPrint("Base URL: \(String(request.url?.absoluteString ?? "")) \r\n Request: \(String(data: request.httpBody ?? Data(), encoding: .utf8)) \r\n Response: \(String(data: data, encoding: .utf8) ?? "error")")
                        let genericModel = try JSONDecoder().decode(decodingType, from: data)
                        completion(genericModel, nil)
                    } catch {
                        completion(nil, .jsonConversionFailure)
                    }
                } else {
                    completion(nil, .invalidData)
                }
            }else if httpResponse.status! == .unauthorized {
                debugPrint(data?.toString() ?? "")
                completion(nil, .unauthorized)
            }
            
        }
        return task
    }
    
    /// To make the a request with the given data
    ///
    /// - Parameters:
    ///   - request: urlrequest
    ///   - decode: decode object
    ///   - completion: check Result<T, APIError>
    internal func fetch<T: Codable>(with request: URLRequest, decode: @escaping (Codable) -> T?, completion: @escaping (Result<T, APIError>) -> Void) {
        //self.index = 0
        let task = decodingTask(with: request, decodingType: T.self) { (json , error) in
            //MARK: change to main queue
            DispatchQueue.main.async {
                guard let json = json else {
                    if let error = error {
                        completion(Result.failure(error))
                    } else {
                        completion(Result.failure(.invalidData))
                    }
                    return
                }
                if let value = decode(json) {
                    completion(.success(value))
                } else {
                    completion(.failure(.jsonParsingFailure))
                }
            }
        }
        task.resume()
    }
    
}


