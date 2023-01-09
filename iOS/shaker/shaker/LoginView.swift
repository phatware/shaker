//
//  LoginView.swift
//  shaker
//
//  Created by Stan Miasnikov on 12/26/22.
//

import SwiftUI
import AuthenticationServices
import Security

struct TitleView: View {
    var body: some View {
        VStack(spacing: 20.0) {
            
            Spacer()
                .frame(height: 175)
            
            Text("Create Account or Login")
                .foregroundColor(.yellow)
                .font(.largeTitle)
                .shadow(radius: 4)
                .frame(height: 100)
                
            Spacer()
            
        }
        .multilineTextAlignment(.center)
    }
}

struct LoginView: View {
    
    var body: some View {
        VStack {
            ZStack {
                Image("login1")
                    .scaledToFit()
                //                    // .luminanceToAlpha()
                TitleView()
                
                VStack(spacing: 20) {
                    // Add google login
                    //                GoogleSignInButton()
                    //                    .frame(height: 45, alignment: .center)
                    //                    .buttonStyle(PlainButtonStyle())
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            // 1
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success (let authResults):
                                // 2
                                print("Authorization successful.")
                                if let authCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    print("User: \(authCredential.user)")
                                    print("Full Name: \(String(describing: authCredential.fullName))")
                                    print("Email: \(String(describing: authCredential.email))")
                                    print("Real User Status: \(authCredential.realUserStatus)")
                                    print("Authorization Code: \(String(describing: authCredential.authorizationCode))")
                                }
                                // TODO: send to the server
                                
                            case .failure (let error):
                                // 3
                                print("Authorization failed: " + error.localizedDescription)
                            }
                        }
                    )
                    .frame(width: 260, height: 42, alignment: .center)
                    .buttonStyle(PlainButtonStyle())
                    .shadow(radius: 2)
                    Button(action: {
                        // TODO: implement other login
                        //                    if logged {
                        //                        manager.logOut()
                        //                        email = ""
                        //                        logged = false
                        //                    } else {
                        //                        manager.logIn(permissions: ["public_profile", "email"], from: nil) { (result, error) in
                        //                            if error != nil {
                        //                                print(error!.localizedDescription)
                        //                                return
                        //                            }
                        //                            if !result!.isCancelled {
                        //                                logged = true
                        //                                let request = GraphRequest(graphPath: "me", parameters: ["fields": "email"])
                        //                                request.start { (_, res, _) in
                        //                                    guard let profileData = res as? [String: Any] else { return }
                        //                                    email = profileData["email"] as! String
                        //                                }
                        //                            }
                        //                        }
                        //                    }
                    }, label: {
                        Text("Login With")
                            .fontWeight(.regular)
                            .foregroundColor(.white)
                            .frame(width: 260, height: 42, alignment: .center)
                            .background(Color.blue)
                            .cornerRadius(8)
                    })
                    .shadow(radius: 2)
                }
            }
            .onAppear() {
                KeychainItem.deleteUserIdentifierFromKeychain()
            }
        }
    }
    
    func login()
    {
        let url = URL(string: "http://www.phatware.com/shaker/api/v1")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Api-Client-Id"      : "CLIENT_ID",
            "Api-Client-Secret"  : "CLIENT_SECRET",
            "Api-User-Id"        : "[DataModel sharedModel].userId",
            "Api-Client-Version" : "[SystemUtilities build]"
        ]
        
        URLSession.shared.dataTask(with: request) { (response, data, error) in

        }

    }
}

enum KeychainError : Error
{
    case error1
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

struct KeychainItem {
    
    var service : String
    var account : String
    var accessGroup : String?
    
    init(service: String, account: String, accessGroup: String? = nil)
    {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }
    
    static func deleteUserIdentifierFromKeychain()
    {
        do { //please change service id to your bundle ID
            try KeychainItem(service: "com.phatware.shaker", account: "userIdentifier").deleteItem()
        } catch {
            print("Unable to delete userIdentifier from keychain")
        }
    }
    
    func deleteItem() throws
    {
        // Delete the existing item from the keychain.
        let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.error1 }
    }
    
    private static func keychainQuery(withService service: String,
                                      account: String? = nil,
                                      accessGroup: String? = nil) -> [String: AnyObject]
    {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}
