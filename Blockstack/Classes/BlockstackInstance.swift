//
//  BlockstackInstance.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-16.
//

import Foundation
import SafariServices
import JavaScriptCore
import secp256k1

public enum BlockstackConstants {
    static let DefaultCoreAPIURL = "https://core.blockstack.org"
    static let BrowserWebAppURL = "https://browser.blockstack.org"
    static let BrowserWebAppAuthEndpoint = "http://localhost:3000/auth"
    static let AuthProtocolVersion = "1.1.0"
}

open class BlockstackInstance {
    open var coreAPIURL = BlockstackConstants.DefaultCoreAPIURL
    var sfAuthSession : SFAuthenticationSession?
    
    open func signIn(redirectURI: String,
                     appDomain: URL,
                     manifestURI: URL? = nil,
                     scopes: Array<String> = ["store_write"],
                     completion: ((AuthResult) -> Void)?) {
        print("signing in")
        print("using core api url: ", coreAPIURL)
        
        guard let transitKey = Keys.generateTransitKey() else {
            print("Failed to generate transit key")
            return
        }
        
        let _manifestURI = manifestURI ?? URL(string: "/manifest.json", relativeTo: appDomain)
        let appBundleID = "AppBundleID"
        
//        print("transitKey", transitKey)
//        print("redirectURLScheme", redirectURI)
//        print("manifestURI", _manifestURI!.absoluteString)
//        print("appDomain", appDomain)
//        print("appBundleID", appBundleID)
        
        let authRequest: String = Auth.makeRequest(transitPrivateKey: transitKey,
                                                   redirectURLScheme: redirectURI,
                                                   manifestURI: _manifestURI!,
                                                   appDomain: appDomain,
                                                   appBundleID: appBundleID)

        startSignIn(redirectURLScheme: redirectURI, authRequest: authRequest) { (url, error) in
            guard error == nil else {
                completion?(AuthResult.failed(error))
                return
            }

            if let queryParams = url!.queryParameters {
                let authResponse: String = queryParams["authResponse"]!
                Auth.handleResponse(authResponse, transitPrivateKey: transitKey)
                
            }

//            print(url!.queryParameters)
        }
    }

    func startSignIn(redirectURLScheme: String,
                     authRequest: String,
                     completion: @escaping SFAuthenticationSession.CompletionHandler) {
        
        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest)]
        let url = urlComps.url!
        
        print(url)
        
        sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: redirectURLScheme, completionHandler: completion)
        sfAuthSession?.start()
    }
    
}
