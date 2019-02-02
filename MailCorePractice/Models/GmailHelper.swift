//
//  GmailHelper.swift
//  MailCorePractice
//
//  Created by Koh Jia Rong on 2019/2/2.
//  Copyright © 2019 Koh Jia Rong. All rights reserved.
//

import Foundation
import GTMAppAuth
import AppAuth

class GmailHelper: NSObject {
    static let shared = GmailHelper()
    
    let kIssuer = "https://accounts.google.com"
    let kClientID = "382696408917-r139aava2dj6jlgluatmoqnc019vplo8.apps.googleusercontent.com"
    let kRedirectURI = "com.googleusercontent.apps.382696408917-r139aava2dj6jlgluatmoqnc019vplo8:/oauthredirect"
    let kExampleAuthorizerKey = "googleOAuthCodingKey"
    
    var authorization: GTMAppAuthFetcherAuthorization?

    override init() {
        super.init()
        
        loadState()
    }
    
    func loadState() {
        if let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: kExampleAuthorizerKey) {
            if authorization.canAuthorize() {
                self.authorization = authorization
            } else {
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: kExampleAuthorizerKey)
            }
        }
    }
    
    func checkIfAuthorizationIsValid(completion: @escaping (_ authorized: Bool) -> Void) {
        let fetcherService = GTMSessionFetcherService()
        fetcherService.authorizer = self.authorization
        
        guard let userInfoEndpoint = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo") else {return}
        let fetcher = fetcherService.fetcher(with: userInfoEndpoint)
        
        fetcher.beginFetch { (data, error) in
            if let error = error {
                self.authorization = nil
                completion(false)
                NSLog("Error checking if authorization is valid:", error.localizedDescription)
                return
            }
            
            NSLog("Authorization is valid")
            completion(true)
        }
    }
    
    func doEmailLoginIfRequired(viewController: UIViewController, completion: @escaping () -> ()) {
        self.checkIfAuthorizationIsValid { (authorized) in
            if authorized {
                completion()
            } else {
                self.doInitialAuthorization(viewController: viewController, completion: completion)
            }
        }
    }
    
    func doInitialAuthorization(viewController: UIViewController, completion: @escaping () -> ()) {
        let issuer = URL(string: kIssuer)!
        let redirectURI = URL(string: kRedirectURI)!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { (configuration, error) in
            if let error = error {
                NSLog("Error discovering configuration:", error.localizedDescription)
                self.authorization = nil
                return
            }
            
            if let configuration = configuration {
                let scopes = [OIDScopeOpenID, OIDScopeProfile, "https://mail.google.com/"]
                let request = OIDAuthorizationRequest(configuration: configuration, clientId: self.kClientID, scopes: scopes, redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
                
                appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: viewController, callback: { (authState, error) in
                    if let error = error {
                        NSLog("Error AuthState:", error.localizedDescription)
                        self.authorization = nil
                        return
                    }
                    
                    if let authState = authState {
                        self.authorization = GTMAppAuthFetcherAuthorization(authState: authState)
                        self.saveState()
                        completion()
                    } else {
                        self.authorization = nil
                    }
                })
            }
        }
    }
    
    func saveState() {
        if let authorization = authorization {
            if authorization.canAuthorize() {
                GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: kExampleAuthorizerKey)
            } else {
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: kExampleAuthorizerKey)
            }
        }
    }
}
