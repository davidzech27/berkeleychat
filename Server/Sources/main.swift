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

_ = try await server.flatMap {
    $0.onClose
}.get()
