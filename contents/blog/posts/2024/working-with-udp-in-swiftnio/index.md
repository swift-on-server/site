---
title: "Working with UDP in SwiftNIO"
description: "Create UDP servers and clients using SwiftNIO and structured concurrency"
image: ./assets/cover.jpg
publication: "2024/08/29 9:00:00"
tags:
  - swiftnio
  - networking
  - server
authors:
  - joannis-orlandos
---

# Working with UDP in SwiftNIO

When you visit this website, you're using an HTTP connection to fetch the content. HTTP/1 and HTTP/2 both use TCP sockets to establish a connection.

TCP is a helpful tool, as it provides reliability to your network connections, guaranteeing a datastream's integrity in and delivery through receipts. These receipts, however, do incur additional overhead on the connection. When a TCP packet is lost, the connection will wait for the packet to be retransmitted before continuing. This can be a problem for applications that need to send data quickly, such as online games and audio/video calls where real-time interaction is critical. For some applications, this overhead is too much or simply unnecessary, and they prefer to use UDP instead.

### What is UDP?

UDP is a core networking protocol like TCP, built on top of IPv4 and IPv6. It's a simple protocol that omits delivery checks, which can cause data to be lost. However, this simplicity allows UDP to be faster than TCP, as it doesn't wait for lost packets to be retransmitted.

In this tutorial, you'll learn how to build a UDP server using SwiftNIO. You'll build a simple UDP echo server that listens for incoming packets, reads a string, and sends them back in reverse to the client. By the end of this tutorial, you'll know how to create a UDP server using SwiftNIO and how to send and receive UDP packets.

## How UDP Works

Unlike TCP, UDP sockets don't distinguish between client and server. Any client that sends a packet to a UDP socket needs to bind to a port to receive a response. This makes UDP a connectionless protocol, as it doesn't establish a connection before sending data. Instead, it sends packets directly to the destination.

In order to start accepting packets, bind a UDP socket to a port:

```swift
// 1.
let server = try await DatagramBootstrap(group: NIOSingletons.posixEventLoopGroup)
    // 2.
    .bind(host: "0.0.0.0", port: 2048)
    .flatMapThrowing { channel in
        // 3.
        return try NIOAsyncChannel(
            wrappingChannelSynchronously: channel,
            configuration: NIOAsyncChannel.Configuration(
                // 4.
                inboundType: AddressedEnvelope<ByteBuffer>.self,
                outboundType: AddressedEnvelope<ByteBuffer>.self
            )
        )
    }
    .get()
```

1. First, create a ``DatagramBootstrap`` to open a UDP socket.
2. Next, bind the socket to a port using the `bind` method.
3. Before completing the setup, transform the created ``Channel`` by wrapping it in a ``NIOAsyncChannel``
4. Unlike TCP, a UDP server does not receive _connections_. It receives an ``AddressedEnvelope`` containing a ``ByteBuffer`` and the sender's ``NIOCore/SocketAddress``.

Now that you've bound the socket, you can start receiving packets.

### Receiving and Sending Packets

First, start observing the socket using ``NIOAsyncChannel/executeThenClose(_:) ((NIOAsyncChannelInboundStream<Inbound>, NIOAsyncChannelOutboundWriter<Outbound>) -> Result)``. This method will provide an `inbound` and `outbound` argument.

Inbound is a stream of incoming packets, whereas outbound is a writer that you can write packets to.

```swift
try await server.executeThenClose { inbound, outbound in
    for try await var packet in inbound {
        // 1.
        guard let string = packet.data.readString(length: packet.data.readableBytes) else {
            continue
        }

        // 2.
        let response = ByteBuffer(string: String(string.reversed()))

        // 3.
        try await outbound.write(AddressedEnvelope(remoteAddress: packet.remoteAddress, data: response))
    }
}
```

1. Each packet received in `inbound` is read into a String
2. The string is reversed, and packet back into a ByteBuffer. This is not very optimised, nor a real use case, but serves a as simple example.
3. The packet is written back, addressed to the `remoteAddress` that sent the original packet.

### Testing the Server

The nc (NetCat) command is a popular tool for managing network connections. Its main use is to establish and handle them. After your code is ready, start the app on your Mac, and run the following command in your terminal:

```sh
echo "Hello, UDP" | nc -u 127.0.0.1 2048 -p 2049
```

- `-u` creates a UDP socket with NetCat
- `127.0.0.1 2048` is the IP address of your UDP server
- `-p 2049` is the port number where you're receiving replies

You'll now see the following in your terminal window:

```sh
PDU ,olleH
```
