// snippet.imports
import NIOCore
import NIOPosix
import NIOHTTP1
// snippet.end

// snippet.bootstrap
// 1
let httpClientBootstrap = ClientBootstrap(group: NIOSingletons.posixEventLoopGroup)
    // 2
    .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    // 3
    .channelInitializer { channel in
        // 4
        channel.pipeline.addHTTPClientHandlers(
            position: .first,
            leftOverBytesStrategy: .fireError
        )
    }
// snippet.end

// snippet.partial
enum HTTPPartialResponse {
    case none
    case receiving(HTTPResponseHead, ByteBuffer)
}
// snippet.end

// snippet.error
enum HTTPClientError: Error {
    case malformedResponse, unexpectedEndOfStream
}
// snippet.end

// snippet.client
struct HTTPClient {
    let host: String

    func request(_ uri: String, method: HTTPMethod = .GET, headers: HTTPHeaders = [:]) async throws -> (HTTPResponseHead, ByteBuffer) {
        // 1
        let clientChannel = try await httpClientBootstrap.connect(
            host: host,
            port: 80
        ).flatMapThrowing { channel in
            // 2
            try NIOAsyncChannel(
                wrappingChannelSynchronously: channel,
                configuration: NIOAsyncChannel.Configuration(
                    inboundType: HTTPClientResponsePart.self, // 3
                    outboundType: HTTPClientRequestPart.self // 4
                )
            )
        }.get() // 5
        // snippet.end

        // snippet.executeThenClose
        // 1
        return try await clientChannel.executeThenClose { inbound, outbound in
            // 2
            try await outbound.write(.head(HTTPRequestHead(version: .http1_1, method: method, uri: uri, headers: headers)))
            try await outbound.write(.end(nil))
            // snippet.end

            // snippet.httpLogic
            var partialResponse = HTTPPartialResponse.none

            // 1
            for try await part in inbound {
                // 2
                switch part {
                case .head(let head):
                    guard case .none = partialResponse else {
                        throw HTTPClientError.malformedResponse
                    }

                    let buffer = clientChannel.channel.allocator.buffer(capacity: 0)
                    partialResponse = .receiving(head, buffer)
                case .body(let buffer):
                    guard case .receiving(let head, var existingBuffer) = partialResponse else {
                        throw HTTPClientError.malformedResponse
                    }

                    existingBuffer.writeImmutableBuffer(buffer)
                    partialResponse = .receiving(head, existingBuffer)
                case .end:
                    guard case .receiving(let head, let buffer) = partialResponse else {
                        throw HTTPClientError.malformedResponse
                    }

                    return (head, buffer)
                }
            }

            // 3
            throw HTTPClientError.unexpectedEndOfStream
            // snippet.end
        }
    }
}

// snippet.usage
let client = HTTPClient(host: "example.com")
let (response, body) = try await client.request("/", headers: ["Host": "example.com"])
print(response)
print(body.getString(at: 0, length: body.readableBytes)!)
// snippet.end
