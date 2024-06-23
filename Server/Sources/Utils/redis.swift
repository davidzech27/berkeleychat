import Foundation
import NIOCore
import RediStack

func createRedisConnectionPool(hostname: String, password: String) async throws -> RedisConnectionPool {
    let eventLoop: EventLoop = NIOSingletons.posixEventLoopGroup.any()

    return RedisConnectionPool(
        configuration: .init(initialServerConnectionAddresses: [try! SocketAddress.makeAddressResolvingHost(
            String(hostname.split(separator: ":")[0]),
            port: Int(hostname.split(separator: ":")[1])!
        )],
        maximumConnectionCount: .maximumPreservedConnections(2),
        connectionFactoryConfiguration: .init(connectionPassword: password)),
        boundEventLoop: eventLoop
    )
}

extension RedisConnectionPool: @unchecked Sendable {}
