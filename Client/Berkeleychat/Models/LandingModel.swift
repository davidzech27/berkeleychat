//
//  LandingScreenModel.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import Foundation
import SwiftUI

enum LandingScreen: Equatable {
    case loading
    case googleSignIn
    case profilePhoto(accessToken: String, email: String, name: String)
    case major(accessToken: String, email: String, name: String, profilePhotoUrl: String)
    case courses(accessToken: String, email: String, name: String, profilePhotoUrl: String, major: String)
    case intro(accessToken: String, email: String, name: String, profilePhotoUrl: String, major: String, courses: [String])
    case complete(accessToken: String, email: String, name: String, profilePhotoUrl: String, major: String, courses: [String], introUrl: String)
}

@Observable
class LandingModel {
    var grpcModel: GRPCModel
    var authModel: AuthModel

    init(grpcModel: GRPCModel, authModel: AuthModel) {
        self.grpcModel = grpcModel
        self.authModel = authModel
    }

    var landingScreen: LandingScreen {
        guard let localUser = authModel.localUser else {
            return .loading
        }
        guard let accessToken = localUser.accessToken, let email = localUser.email, let name = localUser.name else {
            return .googleSignIn
        }
        guard let profilePhotoUrl = localUser.profilePhotoUrl else {
            return .profilePhoto(accessToken: accessToken, email: email, name: name)
        }
        guard let major = localUser.major else {
            return .major(accessToken: accessToken, email: email, name: name, profilePhotoUrl: profilePhotoUrl)
        }
        guard let courses = localUser.courses else {
            return .courses(accessToken: accessToken, email: email, name: name, profilePhotoUrl: profilePhotoUrl, major: major)
        }
        guard let introUrl = localUser.introUrl else {
            return .intro(accessToken: accessToken, email: email, name: name, profilePhotoUrl: profilePhotoUrl, major: major, courses: courses)
        }
        return .complete(accessToken: accessToken, email: email, name: name, profilePhotoUrl: profilePhotoUrl, major: major, courses: courses, introUrl: introUrl)
    }
}
