//
//  AuthModel.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import Foundation
import GoogleSignIn
import SwiftUI

@Observable
class LocalUserModel {
    var accessToken: String?
    var email: String?
    var name: String?

    var profilePhotoUrl: String? = UserDefaults.standard.string(forKey: "profilePhotoUrl") {
        didSet {
            UserDefaults.standard.set(profilePhotoUrl, forKey: "profilePhotoUrl")
        }
    }

    var major: String? = UserDefaults.standard.string(forKey: "major") {
        didSet {
            UserDefaults.standard.set(major, forKey: "major")
        }
    }

    var courses: [String]? = UserDefaults.standard.stringArray(forKey: "courses") {
        didSet {
            UserDefaults.standard.set(courses, forKey: "courses")
        }
    }

    var introUrl: String? = UserDefaults.standard.string(forKey: "introUrl") {
        didSet {
            UserDefaults.standard.set(introUrl, forKey: "introUrl")
        }
    }

    static func empty() -> LocalUserModel {
        let localUser = LocalUserModel(accessToken: nil, email: nil, name: nil)
        localUser.profilePhotoUrl = nil
        localUser.major = nil
        localUser.courses = nil
        localUser.introUrl = nil

        return localUser
    }

    static func withCredentials(accessToken: String, email: String, name: String) -> LocalUserModel {
        LocalUserModel(accessToken: accessToken, email: email, name: name)
    }

    private init(accessToken: String?, email: String?, name: String?) {
        self.accessToken = accessToken
        self.email = email
        self.name = name
    }
}

@Observable
class AuthModel {
    var localUser: LocalUserModel?

    func loadLocalUser() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { result, error in
            guard let profile = result?.profile, let accessToken = result?.accessToken.tokenString, error == nil else {
                self.localUser = LocalUserModel.empty()

                return
            }

            self.localUser = LocalUserModel.withCredentials(
                accessToken: accessToken,
                email: profile.email,
                name: profile.name
            )
        }
    }

    func signInWithGoogle() {
        guard let rootViewController = (UIApplication.shared.connectedScenes.first
            as? UIWindowScene)?.windows.first?.rootViewController
        else {
            print("Root view controller not found")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController)
        { result, error in
            if let error = error {
                print("Error signing in with Google", error)
            }

            guard let profile = result?.user.profile, let accessToken = result?.user.accessToken.tokenString else {
                print("Google profile not found")
                return
            }

            self.localUser = LocalUserModel.withCredentials(
                accessToken: accessToken,
                email: profile.email,
                name: profile.name
            )
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()

        localUser = LocalUserModel.empty()
    }
}
