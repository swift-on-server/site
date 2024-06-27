import ArgumentParser
import AsyncAlgorithms
import Foundation
import Hummingbird
import HummingbirdWebSocket
import HummingbirdWSCompression
import Logging
import ServiceLifecycle

struct ConnectionManager: Service {

    // snippet.hide
    typealias OutputStream = AsyncChannel<WebSocketOutboundWriter.OutboundFrame>

    struct Connection {
        let name: String
        let inbound: WebSocketInboundStream
        let outbound: OutputStream
    }

    actor OutboundConnections {
        
        var outboundWriters: [String: OutputStream]

        init() {
            self.outboundWriters = [:]
        }
        
        func send(_ output: String) async {
            for outbound in outboundWriters.values {
                await outbound.send(.text(output))
            }
        }
        
        func add(name: String, outbound: OutputStream) async {
            outboundWriters[name] = outbound
            await send("\(name) joined")
        }

        func remove(name: String) async {
            outboundWriters[name] = nil
            await send("\(name) left")
        }
    }

    let connectionStream: AsyncStream<Connection>
    let connectionContinuation: AsyncStream<Connection>.Continuation
    let logger: Logger

    init(logger: Logger) {
        let stream = AsyncStream<Connection>.makeStream()
        self.connectionStream = stream.stream
        self.connectionContinuation = stream.continuation
        self.logger = logger
    }

    func run() async {}

    // snippet.show

    // ...
    func addUser(
        name: String,
        inbound: WebSocketInboundStream,
        outbound: WebSocketOutboundWriter
    ) -> OutputStream {
        let outputStream = OutputStream()
        let connection = Connection(
            name: name,
            inbound: inbound,
            outbound: outputStream
        )
        connectionContinuation.yield(connection)
        return outputStream
    }
}