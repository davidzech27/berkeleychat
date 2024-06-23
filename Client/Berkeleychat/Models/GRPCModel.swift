import Foundation
import GRPC
import NIOCore
import SwiftUI

let host = "172.20.10.7"

@Observable
class GRPCModel {
    var client: Berkeleychat_BerkeleychatAsyncClient
    private var group: EventLoopGroup?

    init() throws {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)

        let channel = try GRPCChannelPool.with(
            target: .host(host, port: 8080),
            transportSecurity: .plaintext,
            eventLoopGroup: group
        )

        client = Berkeleychat_BerkeleychatAsyncClient(channel: channel)
        self.group = group
    }

    deinit {
        try? group?.syncShutdownGracefully()
    }

    func uploadPhoto(photo: UIImage, accessToken: String) async throws -> String {
        try await client.uploadPhoto(Berkeleychat_UploadPhotoRequest.with {
            $0.accessToken = accessToken
            $0.photo = photo.jpegData(compressionQuality: 0.5)!
        }
        ).photoURL
    }

    func uploadAudio(audio: Data, accessToken: String) async throws -> String {
        try await client.uploadAudio(Berkeleychat_UploadAudioRequest.with {
            $0.accessToken = accessToken
            $0.audio = audio
        }
        ).audioURL
    }

    func createAccount(accessToken: String, email: String, name: String, profilePhotoUrl: String, major: String, courses: [String], introUrl: String) async throws {
        _ = try await client.createAccount(Berkeleychat_CreateAccountRequest.with {
            $0.accessToken = accessToken
            $0.email = email
            $0.name = name
            $0.profilePhotoURL = profilePhotoUrl
            $0.major = major
            $0.courses = courses
            $0.introURL = introUrl
        }
        )
    }
}
