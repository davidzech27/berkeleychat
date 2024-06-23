import AsyncHTTPClient
import Foundation
import GRPC

loadEnvironmentVariables()

let port = ProcessInfo.processInfo.environment["PORT"]
guard let port = port, Int(port) != nil else {
    fatalError("PORT environment variable not set")
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
defer {
    try! group.syncShutdownGracefully()
}

let redis = try! await createRedisConnectionPool(hostname: ProcessInfo.processInfo.environment["REDIS_HOSTNAME"]!, password: ProcessInfo.processInfo.environment["REDIS_PASSWORD"]!)
let s3 = S3Uploader(accessKey: ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"]!, secretKey: ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"]!, region: .uswest1, bucketName: "berkeleychat")
let httpClient = HTTPClient(eventLoopGroupProvider: .shared(group))

let provider = BerkeleychatProvider(redis: redis, s3: s3, httpClient: httpClient)

import NIO
import NIOHTTP1

let server = Server.insecure(group: group)
    .withServiceProviders([provider])
    .bind(host: "localhost", port: Int(port)!)

server.map {
    $0.channel.localAddress
}.whenSuccess { address in
    print("server started on port \(address!.port!)")
}

let channel = try GRPCChannelPool.with(
    target: .host("localhost", port: 8080),
    transportSecurity: .plaintext,
    eventLoopGroup: group
)

let client = Berkeleychat_BerkeleychatAsyncClient(channel: channel)

// manual user creation

// _ = try await client.createAccount(Berkeleychat_CreateAccountRequest.with {
//    $0.email = "ethankolasky@berkeley.edu"
//    $0.name = "Ethan Kolasky"
//    $0.profilePhotoURL = "https://berkeleychat.s3.us-west-1.amazonaws.com/Selfie%202024-06-23%20at%2008.50.49%20%281%29.png"
//    $0.major = "Computer Science"
//    $0.courses = ["EECS 16A"]
//    $0.introURL = "https://berkeleychat.s3.us-west-1.amazonaws.com/UC%20Berkeley.m4a"
// }
// )

// _ = try await client.createAccount(Berkeleychat_CreateAccountRequest.with {
//    $0.email = "vedantgosavi@berkeley.edu"
//    $0.name = "Vedant Gosavi"
//    $0.profilePhotoURL = "https://berkeleychat.s3.us-west-1.amazonaws.com/Selfie%202024-06-23%20at%2008.50.51%20%281%29.png"
//    $0.major = "Computer Science"
//    $0.courses = []
//    $0.introURL = "https://berkeleychat.s3.us-west-1.amazonaws.com/UC%20Berkeley%202.m4a"
// }
// )

// _ = try await client.createAccount(Berkeleychat_CreateAccountRequest.with {
//    $0.email = "ArnavChoudhury@berkeley.edu"
//    $0.name = "Arnav Choudhury"
//    $0.profilePhotoURL = "https://berkeleychat.s3.us-west-1.amazonaws.com/Selfie%202024-06-23%20at%2008.50.35%20%281%29.png"
//    $0.major = "Computer Science"
//    $0.courses = []
//    $0.introURL = "https://berkeleychat.s3.us-west-1.amazonaws.com/UC%20Berkeley%203.m4a"
// }
// )

_ = try await server.flatMap {
    $0.onClose
}.get()
