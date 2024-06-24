import ArgumentParser
import AsyncAlgorithms
import Foundation
import Hummingbird
import HummingbirdWebSocket
import HummingbirdWSCompression
import Logging
import ServiceLifecycle

struct ConnectionManager: Service {

    // 1.
    typealias OutputStream = AsyncChannel<WebSocketOutboundWriter.OutboundFrame>

    // 2.
    struct Connection {
        let name: String
        let inbound: WebSocketInboundStream
        let outbound: OutputStream
    }

    // 3.
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

    // snippet.hide
    func run() async {}
    // snippet.show
}
