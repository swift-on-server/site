---
type: devlog
title: "SwiftNIO on Windows"
description: "Covering my journey of getting SwiftNIO to work on Windows"
image: ./assets/cover.jpg
publication: "2025/12/29 9:00:00"
tags:
    - swiftnio
authors:
    - joannis-orlandos
---

# SwiftNIO on Windows

I **love** SwiftNIO. I think my many articles and packages are a testament to that. Before SwiftNIO existed, back in 2016, I was working on the Vapor core team. As part of designing Vapor 3, we needed a better way to handle networking. As any sane developer would, I built my own networking library. Creatively enough we named it ["async"](https://github.com/vapor-community/async). We initially developed all Vapor libraries in a monorepo before Tanner split the project into multiple packages.

These days we're lucky to have SwiftNIO. It's powerful, performant, and integrates with something I love even more: structured concurrency. And for years we've been wanting to use our packages on Windows. This blog (swiftonserver.com) gets a major amount of search engine traffic from Windows users looking to use Swift. It's no surprise then that the [Swift Server Workgroup](https://swift.org/sswg/) has been discussing this extensively for years.

SwiftNIO is the cornerstone of Swift on Linux, and *many* packages use it as a cornerstone. So naturally, this needs to work on Windows as well. Easy? Think again.

## Prior Art

Through the years, [Saleem - or compnerd](https://github.com/compnerd) has been the driving force behind getting Swift to work on Windows. He's also made various PRs to SwiftNIO to get it to work on Windows, but unfortunately none of them were merged in the end. A couple months ago, Apple finally started working on Windows support as well. It's a slow and steady process, but I thought it was time to try and help out.

So far I've gotten every package to build and run on Windows. So let's dive into the how, and what's left to do.

## EventLoop

For those unfamiliar with an EventLoop, let's get into that first as they're very essential to SwiftNIO.

An EventLoop is essetially `while true` (or while running) loop that is responsible for handling _events_. Events are things that happen in the system, and we can really categorize them into two types:
- **I/O events**: These are events that are triggered by I/O operations, such as reading from a file or network socket.
- **Time events**: These are events that are triggered by the passage of time, such as a timeout or a deadline.

Once an event is triggered, the EventLoop will dispatch it to the appropriate handler. This handler is responsible for handling the event.

For example; if a socket receives data, the Eventloop will notify the `Channel` (socket abstraction), that a _readability_ event has been triggered. The `Channel` will then notify the user code that the socket is readable, which in turn can trigger a read operation.

Inversely, if the user code wants to write data to the socket, the `Channel` will try to write it directly. But if the socket buffers are full, the socket _is not writable_. In this case, the EventLoop will notify the `Channel` that a _writability_ event has been triggered.

Time Events are useful too! They're triggered by the passave of time. And scheduling with a delay of zero usually wakes up the EventLoop immediately.

### kqueue, epoll and WSAPoll

Each Operating System has its own way of handling events. On Linux, the old-school custom is to use `epoll` for... polling events.

Now many folks may be familiar with the saying "don't block the EventLoop". Well fully story; when an EventLoop polls for events, it's blocking itself! But it's fine, because it'll wake up when the event is triggered.
It's really the only place in the EventLoop that's allowed to block. But by other operations blocking the EventLoop, you're preventing the EventLoop from polling more events. Effectively you're halting any _other_ operations.

If you manage to block for I/O events, you're going to deadlock the EventLoop - as you're waiting for a I/O that the EventLoop is supposed to provide by polling...

On macOS/Darwin and BSD platforms, the equivalent API is `kqueue`. It works similarly enough. Windows is a bit different.

Windows development is built on IOCPs (I/O Completion Ports). IOCPs are a way to handle I/O operations asynchronously. IOCP works by registering a callback with the Windows kernel, and then the kernel will call the callback when the I/O operation is complete. It's pretty fast, and Linux has recently adopted the pattern through the `io_uring` API.

IOCP doesn't map to NIO's current EventLoop model very well though; and SwiftNIO is not alone. Many other libraries have similar issues.

## WSAPoll; our saviour?

Since Windows 10, Microsoft has introduced `WSAPoll`. WSAPoll is _their_ way to poll for events on Windows. You get to register a list of sockets and events you're interested in, and it'll return a list of events that happened. Pretty much exactly what we need.

The first implementation I did was to wire WSAPoll to the same way macOS and Linux are implemented. User code would register a socket and events they're interested in, and the EventLoop would poll for events.

Once a user connects a TCP or UDP socket, a Winsock is created. The file descriptor is added to the EventLoop's socket set, and the EventLoop would poll for events.
If you receive data from the socket, the EventLoop would dispatch a readability event to the user code. And writability worked too! We're done right?

### If only we could use IOCP...

Next I tried to spawn a server socket. Server sockets bind to a port and listen for connections. When a connection is established, a new socket is created for the connection.
When NIO accepts a connection, it runs some asynchronous accept logic like setting up the "pipeline" (protocol handlers). Once those are set up, the socket is added to the EventLoop.

In-between accepting the socket and adding the handlers, the EventLoop is able to continue polling for events. As a good citizen, NIO's higher level code keeps the EventLoop unblocked.
However, this means we need to wake up the EventLoop to add the handlers. Because the EventLoop is blocked by the WSAPoll call, we need to spawn a new timer to wake it up.

Oh wait... Windows doesn't have timers. So we'll need a new way to wake up the EventLoop.

An alternative pattern is to have a `Pipe`, where one side is given to the EventLoop, so it wakes up from any events concerning this pipe. The other side is given to the higher level code, so it can write to the pipe to wake up the EventLoop.

This is a bit of a hack, but it's not unheard of. Unfortunately, Windows doesn't have Pipes in the same way UNIX(-like) systems do. So we'll need to find a different way to wake up the EventLoop again...

At this point, there's only one way I could find out to wake up the EventLoop: Create a (datagram) socket to myself. The EventLoop would poll for events on this socket, and when it receives a message, it would wake up and add the handlers. Hacky? Hell yeah, but for a first attempt it works.

### Problem 2

Then I tried setting up a server socket. The HTTP connection gets through, but no data flows in either direction... weird.

I am registering the socket, and then after registering the socket I'm registering the events I'm interested in. That's exactly what I'm doing on Linux and macOS. What's different?
Well, it turns out what WSAPoll doesn't know that the set of events you're interested in has changed. So if you modify the list after calling into WSAPoll, it won't react to those events.

Gulp; guess I'm going to need to wake up my Datagram socket again...

### Light at the end of the tunnel

After a few days of debugging and headscratching, I have to conclude that WSAPoll sucks. But hey, I've got it working!
With TCP and UDP working at _some_ level, I figured to check the higher level packages.

I first tried [Hummingbird](https://hummingbird.codes), which basically immediately worked. It needed a change to how Environment variables are parsed, and I didn't port over NIOFileSystem. But beyond those two; it's just an out of the box experience!

Next up; AsyncHTTPClient. This one has a few more interesting dependencies, including NIOExtras. This package adds handy utilities for NIO like zlib (de)compression.
Windows is the only OS that doesn't bundle zlib, so I had to install it on my PC through `vcpkg`. Then, I needed to point my `swift build` invocation to link against that `.dll` or `.lib`.

It's a bit of a pain, and I hope we can fix that through some [forums discussion](https://forums.swift.org/t/zlib-support-in-the-swift-ecosystem/83792).

I also tried [grpc-swift](https://github.com/grpc/grpc-swift-2), which needed _minor_ adjustments only. And I ported [Noora](https://github.com/tuist/noora) to Windows too. Both of which went without much of a hassle.

As a final stretch, I ported most of the [Wendy CLI](https://github.com/wendylabsinc/wendy-agent) to Windows too. Ultimately that was my goal, and it worked!

## What's next?

There's still a lot of work to do. I need some code reviews on my Windows PRs, and I'm sure we'll want that datagram socket gone if we can. I didn't get most of the test suite passing, and I need to set up Github Actions workflows to run the tests on Windows. Finally, NIOFileSystem needs to be ported to Windows too, which is quite a big project.

Other than that, I'm happy to have SwiftNIO working on Windows! It's early days, but it's a big win I'm excited to share!