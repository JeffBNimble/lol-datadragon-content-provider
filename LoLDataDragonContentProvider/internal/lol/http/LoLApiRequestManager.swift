//
//  LoLApiRequestManager.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire

class LoLApiRequestManager : Alamofire.Manager {
    static let PLACEHOLDER_API_VERSION = LoLApiRequestManager.placeholderWith("api.version")
    static let PLACEHOLDER_ID = LoLApiRequestManager.placeholderWith("id")
    static let PLACEHOLDER_REGION = LoLApiRequestManager.placeholderWith("api.region")
    
    private static func placeholderWith(placeholderIdentifier: String) -> String {
        return "{\(placeholderIdentifier)}"
    }
    
    var completionQueue: dispatch_queue_t?
    
    private var apiKey : String
    private var apiVersion : String
    private var baseURL : String
    private var region : String
    
    convenience init(sessionConfiguration: NSURLSessionConfiguration,
        baseURL: NSURL,
        apiKey: String,
        region: String,
        apiVersion: String,
        completionQueue: dispatch_queue_t? = nil) {
        self.init(configuration: sessionConfiguration, serverTrustPolicyManager: nil)
            self.baseURL = baseURL.absoluteString
            self.apiKey = apiKey
            self.apiVersion = apiVersion
            self.region = region
            self.completionQueue = completionQueue
    }

    required override init(configuration: NSURLSessionConfiguration, delegate: SessionDelegate = SessionDelegate(), serverTrustPolicyManager: ServerTrustPolicyManager?) {
        self.apiKey = ""
        self.apiVersion = ""
        self.region = ""
        self.baseURL = ""
        super.init(configuration: configuration, delegate: delegate, serverTrustPolicyManager: serverTrustPolicyManager)
    }
    
    override func request(method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        parameters: [String : AnyObject]? = nil,
        encoding: ParameterEncoding = .URL,
        headers: [String : String]? = nil) -> Request {
        return super.request(method, self.asAbsoluteURL(URLString), parameters: self.addLoLParameters(parameters), encoding: encoding, headers: headers)
    }

    private func addLoLParameters(parameters: [String : AnyObject]?) -> [String : AnyObject] {
        var queryParameters = [String : AnyObject]()
        if let parameters = parameters {
            for (key, value) in parameters {
                queryParameters[key] = value
            }
        }
        
        queryParameters["api_key"] = self.apiKey
        
        return queryParameters
    }
    
    private func asAbsoluteURL(urlString: URLStringConvertible) -> URLStringConvertible {
        return self.baseURL + self.resolvePlaceholders(urlString).URLString
    }
    
    private func resolvePlaceholders(urlString: URLStringConvertible) -> URLStringConvertible {
        var url = urlString.URLString
        
        var range = url.rangeOfString(LoLApiRequestManager.PLACEHOLDER_API_VERSION)
        if let range = range {
            url.replaceRange(range, with: self.apiVersion)
        }
        
        range = url.rangeOfString(LoLApiRequestManager.PLACEHOLDER_REGION)
        if let range = range {
            url.replaceRange(range, with: self.region)
        }
        
        return url
    }
}
