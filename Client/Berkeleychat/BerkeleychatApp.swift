//
//  BerkeleychatApp.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import GoogleSignIn
import SwiftUI

@main
struct BerkeleychatApp: App {
    let model = Model()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView().onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    model.loadInitialData()

                    // model.auth.signOut()
                }
            }
            .environment(model)
        }
    }
}
