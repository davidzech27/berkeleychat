//
//  GoogleSignInView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import SwiftUI

struct GoogleSignInView: View {
    @Environment(Model.self) var model

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 8) {
                FadingText("Berkeleychat")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()

                FadingText("Let's get started.")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .opacity(0.75)

                Spacer()

                RoundedButton("Sign in with your university email") {
                    model.auth.signInWithGoogle()
                }
            }
            .padding(16)
        }
    }
}

struct GoogleSignInView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        GoogleSignInView()
    }
}
