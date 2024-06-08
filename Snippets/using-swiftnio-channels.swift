import NIOCore
import NIOPosix

// snippet.bootstrap
// 1.
let server = try await ServerBootstrap(group: NIOSingletons.posixEventLoopGroup)
    .bind( // 2.
        host: "0.0.0.0", // 3.
        port: 2048 // 4.
    ) { channel in
        // 5.
        channel.eventLoop.makeCompletedFuture {
            // Add any handlers for parsing or serializing messages here
            // We don't need any for this echo example

            // 6.
            return try NIOAsyncChannel(
                wrappingChannelSynchronously: channel,
                configuration: NIOAsyncChannel.Configuration(
                    inboundType: ByteBuffer.self, // We'll read the raw bytes from the socket
                    outboundType: ByteBuffer.self // We'll also write raw bytes to the socket
                )
            )
        }
    }
// snippet.end

// We create a task group to manage the lifetime of our client connections
// Each client is handled by its own structured task
// snippet.acceptClients
// 1.
try await withThrowingDiscardingTaskGroup { group in
    // 2.
    try await server.executeThenClose { clients in
        // 3.
        for try await client in clients {
            // 4.
            group.addTask {
                // 5.
                try await handleClient(client)
            }
        }
    }
}
// snippet.end

// snippet.handleClient
func handleClient(_ client: NIOAsyncChannel<ByteBuffer, ByteBuffer>) async throws {
    // 1.
    try await client.executeThenClose { inboundMessages, outbound in
        // 2.
        for try await inboundMessage in inboundMessages {
            // 3.
            try await outbound.write(inboundMessage)

            // MARK: A
            return
        }
    }
}
// snippet.end
