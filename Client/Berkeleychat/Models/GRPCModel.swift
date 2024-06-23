import Foundation
import GRPC
import NIOCore
import SwiftUI

let host = "localhost"

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

    func getUsers(email: String, major: String) async throws -> Berkeleychat_GetUsersResponse {
        try (await client.getUsers(Berkeleychat_GetUsersRequest.with {
            $0.email = email
            $0.major = major
        }
        ))
    }

    func getMessages(email: String, onMessage: @escaping (Berkeleychat_Message) -> Void) async throws {
        let stream = client.getMessages(Berkeleychat_GetMessagesRequest.with {
            $0.email = email
        }
        )

        for try await message in stream {
            onMessage(message)
        }
    }

    func sendMessage(content: String, toEmail: String) async throws {
        _ = try await client.sendMessage(Berkeleychat_Message.with {
            $0.content = content
            $0.toEmail = toEmail
        }
        )
    }
}

// syntax = "proto3";

// package berkeleychat;

// service Berkeleychat {
//  rpc UploadPhoto(UploadPhotoRequest) returns (UploadPhotoResponse) {}
//  rpc UploadAudio(UploadAudioRequest) returns (UploadAudioResponse) {}

//  rpc CreateAccount(CreateAccountRequest) returns (CreateAccountResponse) {}

//  rpc GetUsers(GetUsersRequest) returns (GetUsersResponse) {}

//  rpc GetMessages(GetMessagesRequest) returns (stream Message) {}

//  rpc SendMessage(Message) returns (Message) {}
// }

// message UploadPhotoRequest {
//  string access_token = 1;
//  bytes photo = 2;
// }

// message UploadPhotoResponse {
//  string photo_url = 1;
// }

// message UploadAudioRequest {
//  string access_token = 1;
//  bytes audio = 2;
// }

// message UploadAudioResponse {
//  string audio_url = 1;
// }

// message CreateAccountRequest {
//  string access_token = 1;
//  string email = 2;
//  string name = 3;
//  string profile_photo_url = 4;
//  string major = 5;
//  repeated string courses = 6;
//  string intro_url = 7;
// }

// message CreateAccountResponse {
// }

// message GetUsersRequest {
//  string email = 1;
//  string major = 2;
// }

// message GetUsersResponse {
//  repeated User users = 1;
// }

// message User {
//  string email = 1;
//  string name = 2;
//  string profile_photo_url = 4;
//  string major = 5;
//  repeated string courses = 6;
//  string intro_url = 7;
//  repeated string messages = 8;
// }

// message GetMessagesRequest {
//  string email = 1;
// }

// message Message {
//  string to_email = 1;
//  string from_email = 2;
//  string content = 3;
// }

//// message GetPostsRequest {}

//// message GetPostsResponse {
////   message Post {
////     string user_id = 1;
////     string post_id = 2;
////     string content = 3;
////   }

////   repeated Post posts = 1;
//// }

//// message CreatePostRequest {
////   string content = 1;
//// }

//// message CreatePostResponse {
////   string post_id = 1;
//// }
