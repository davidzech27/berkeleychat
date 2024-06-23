//
//  Model.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import Foundation

@Observable
class Model {
    var grpc: GRPCModel
    var auth: AuthModel
    var landing: LandingModel

    init() {
        let grpcNew = try! GRPCModel()
        let authNew = AuthModel()
        let landingNew = LandingModel(grpcModel: grpcNew, authModel: authNew)

        grpc = grpcNew
        auth = authNew
        landing = landingNew
    }

    func loadInitialData() {
        auth.loadLocalUser()
    }
}
