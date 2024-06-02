# WebSocket tutorial using Swift and Hummingbird

In this article, you will learn about WebSockets and how to use them with the Hummingbird framework in a straightforward, easy-to-follow manner. The first part will give a clear understanding of what the WebSocket protocol is. After that, a hands-on example will be created using the Hummingbird WebSocket library, showing how to use this technology effectively.

## What is a WebSocket?

The WebSocket protocol is a communication protocol that enables two-way, real-time interaction between a client and a server. It is designed to work over a single, long-lived connection, which significantly reduces the overhead compared to traditional HTTP request-response cycles. This protocol starts with a WebSocket handshake, which uses HTTP to establish the connection, and then upgrades it to the WebSocket protocol, allowing both the client and server to send and receive messages asynchronously.

WebSockets are particularly useful for applications that require low latency and high-frequency updates, such as online gaming, chat applications, and live data feeds. The protocol supports full-duplex communication, meaning data can be sent and received simultaneously, which enhances performance and responsiveness. This efficient data transfer method helps in creating more interactive applications, providing a smoother user experience.

## WebSockets vs long polling vs HTTP streaming, and server-sent events

Various methods have been used to achieve real-time capabilities by allowing data to be sent directly from the server to clients, but none have been as efficient as WebSockets. Techniques like HTTP polling, HTTP streaming, Comet, and SSE (server-sent events) all have their drawbacks. Let’s explore how these methods differ.

### Long polling (HTTP polling)

Long polling (HTTP polling) was one of the first methods to address real-time data fetching. It involved the client frequently sending requests to the server at regular intervals. Long polling improved on this by having the server hold the request open until there’s new data or a timeout occurs. Once data is available, the server responds, and the client immediately sends a new request. However, long polling had several issues, including header overhead, latency, timeouts, and caching problems.

### HTTP streaming

HTTP streaming reduces network latency by keeping the initial request open indefinitely. Unlike long polling, the server does not close the connection after sending data; it keeps it open to send new updates whenever there is a change. The first few steps of HTTP streaming are similar to long polling, but the key difference is that the connection remains active. This method allows continuous data updates and can be implemented using low-level streaming APIs.

### SSE - Server-sent events

Server-sent events (SSE) allow the server to push data to the client, similar to HTTP streaming. SSE is a standardized version of HTTP streaming and includes a built-in browser API. However, SSE is not suitable for applications like chat or gaming that require two-way communication since it only allows one-way data flow from the server to the client. SSE uses traditional HTTP and has limitations on the number of open connections.

## Why to use WebSockets?

Compared to WebSockets, these methods are less efficient and often seem like workarounds to make a request-reply protocol appear full-duplex. WebSockets are designed to replace existing bidirectional communication methods, as the previously mentioned methods are neither reliable nor efficient for full-duplex real-time communication. WebSockets are similar to SSE but excel in enabling messages to be sent from the client to the server. Connection restrictions are no longer an issue because data is transmitted over a single TCP socket connection.

### Security (WSS)

WebSocket (WS) uses a plain-text HTTP protocol, making it less secure and easy to intercept. WebSocket Secure (WSS), like HTTPS, encrypts data with SSL/TLS, preventing interception and increasing security. WSS protects against man-in-the-middle attacks but does not offer cross-origin or application-level security. Developers should add URL origin checks and strong authentication. 

## How to use WebSockets to build a real-time application?



## Conclusion


https://theswiftdev.com/websockets-for-beginners-using-vapor-4-and-vanilla-javascript/