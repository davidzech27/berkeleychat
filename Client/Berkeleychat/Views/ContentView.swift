//
//  ContentView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

let timingCurve = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.5)

struct ContentView: View {
    @Environment(Model.self) var model

    @Namespace var namespace

    var body: some View {
        VStack {
            switch model.landing.landingScreen {
            case .loading:
                LoadingView()
            case .googleSignIn:
                GoogleSignInView()
            case let .profilePhoto(accessToken, email, name):
                ProfilePhotoView(accessToken: accessToken, email: email, name: name)
            case .major:
                MajorView()
            case .courses:
                CoursesView()
            case let .intro(accessToken, email, name, profilePhotoUrl, major, courses):
                IntroView(accessToken: accessToken, email: email, name: name, profilePhotoUrl: profilePhotoUrl, major: major, courses: courses)
            case let .complete(accessToken, email, name, profilePhotoUrl, major, courses, intro):
                UsersView()
            default:
                Text("Hello, world!")
            }
        }
    }
}
