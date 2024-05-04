---
slug: getting-started-with-citadel-ssh
title: Getting Started with Citadel SSH
description: Learn how to create an SFTP client with Citadel
date: 2024/04/18
tags: Swift, SSH, SFTP
author: Joannis Orlandos
authorLink: https://x.com/JoannisOrlandos
authorGithub: joannis
authorAbout: Joannis is a seasoned member of the Swift Server WorkGroup, and the co-founder of Unbeatable Software B.V. If you're looking to elevate your team's capabilities or need expert guidance on Swift backend development, consider hiring him.
cta: Get in touch with Joannis
ctaLink: https://unbeatable.software/mentoring-and-training
company: Unbeatable Software B.V.
companyLink: https://unbeatable.software/
duration: 30 minutes
---

SSH is an important protocol for logging into remote machines, connecting to a shell or transferring files. The protocol is widely used, and has been around for a long time.

In this tutorial, you'll learn how to create SSH clients and servers with [Citadel](https://github.com/orlandos-nl/Citadel).

### Setting Up

First, your project needs the Citadel dependency in the `Package.swift` file:

```swift
.package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.7.0"),
```
    
Then, add the dependency to your target:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "Citadel", package: "Citadel"),
]),
```

### Creating an SSH Server

To create an SSH server, you need to create a `SSHServer` instance and start it:

```swift
let server = try await SSHServer.host(
    host: "0.0.0.0",
    port: 22,
    hostKeys: [
        // This hostkey changes every app boot, it's more practical to use a pre-generated one
        NIOSSHPrivateKey(ed25519Key: .init())
    ],
    authenticationDelegate: MyCustomMongoDBAuthDelegate(db: mongokitten)
)
```