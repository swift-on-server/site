---
title: "Introduction to JWTs in Swift"
description: "Learn how to use JWTs in Swift to secure your API"
image: ./assets/cover.jpg
publication: "2025/01/09 9:00:00"
tags:
    - authentication
authors:
    - paul-toffoloni
---

# Introduction to JWTs in Swift

JWTKit is a library for working with JSON Web Tokens (JWT) in Swift. It provides a simple and easy-to-use API for creating, parsing, and validating JWTs. JWTs are a popular way to authenticate information (claims) between parties. JWTKit makes it easy to work with them in your Swift projects.

In this tutorial, you'll learn how to use JWTKit to create and validate JWTs in Swift. You'll start by installing JWTKit using Swift Package Manager, then you'll learn how to create a JWT and validate it using JWTKit's API. At the end of this tutorial, you'll be able to implement an authentication and authorisation flow in your Swift projects using JWTs.

## What is a JSON Web Token (JWT)?

A JWT is a compact, URL-safe way to represent claims between two parties. The token is digitally signed, which makes it secure and trustworthy. JWTs are commonly used for authentication and authorisation in (web) applications, APIs, and microservices.

A JWT consists of three parts:

1. A header, containing metadata about the token, such as the type of token and the algorithm used to sign it.
2. The payload, which contains the claims, which are statements about an entity (typically the user) and additional data.
3. And a signature. The signature is used to verify that the token is valid and has not been tampered with.

It usually looks like this:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

If you inspect the token on [jwt.io](https://jwt.io), you'll see that it consists of three parts separated by dots: the header, the payload, and the signature.

> Note: Don't paste production tokens into jwt.io or any other online tool, as they could be intercepted and misused.

## Installing JWTKit

JWTKit is available as a Swift package, which makes it easy to install and use in your projects. To install it, add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0")
]
```

Then, add JWTKit as a dependency to your target:

```swift
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "JWTKit", package: "jwt-kit")
    ])
]
```

## Configuration

In JWTKit everything revolves around the ``JWTKeyCollection`` object: a collection of keys that can be used to sign and verify JWTs. The declaration is simple, you can add this in your app's configuration code:

```swift
let keyCollection = JWTKeyCollection()
```

Adding keys to the collection is also straightforward:

```swift
await keyCollection.add(hmac: "secret", digestAlgorithm: .sha256)
```

This snippet adds an HMAC (Hash-based Message Authentication Code) key to the collection. HMAC is one of the most common algorithms used to sign JWTs. You can read about it [here](https://blog.boot.dev/cryptography/hmac-and-macs-in-jwts/), but in short, it works like this:
1. First, the JWT's content (header and payload) is hashed using SHA-256
2. Then, this hash is combined with our secret key to create a unique signature
3. The same secret key must be used for both signing and verification (that's what makes it "symmetric")

> Important: Since HMAC uses the same key for signing and verification, you must keep this secret key secure and never expose it in client-side code or public repositories. Use environment variables or a secure secrets manager to store it.

> You might be wondering why the `add` method is marked with `await`. This is because the method is asynchronous due to `JWTKeyCollection` being an actor. You can read more about actors in [Sendable and Shared Mutable State](/structured-concurrency-and-shared-state-in-swift/).

Other than HMAC, JWTKit also supports **ECDSA**, **EdDSA** and **RSA** keys. These are asymmetric signing algorithms, which means the key used to sign the JWT is different from the key used to verify it. This article won't go into which algorithm is best as each one has its own use case, however it's important to note that RSA is the least recommended of the listed ones due to different reasons. That's why JWTKit hides RSA keys behind an `Insecure` namespace.

## Creating a JWT

Once you have a ``JWTKeyCollection`` object, you can use it to "create" a JWT. Creating a JWT means signing the payload with a key, in this case one from the collection. The payload is the data we want to transmit securely:

```swift
struct TestPayload: JWTPayload {
    var expiration: ExpirationClaim
    var issuer: IssuerClaim

    enum CodingKeys: String, CodingKey {
        case expiration = "exp"
        case issuer = "iss"
    }

    func verify(using key: some JWTAlgorithm) throws {
        try self.expiration.verifyNotExpired()
    }
}
```

In this example, we define a `TestPayload` struct that conforms to the ``JWTPayload`` protocol. This protocol requires us to implement the ``JWTPayload/verify(using:)`` method, which includes optional additional validation logic that can be performed when creating the JWT. In this case, we're verifying that the token has not expired.
The properties of the struct are the claims we want to include in the JWT. JWTKit provides a number of built-in claims, such as ``ExpirationClaim`` and ``IssuerClaim``, which are commonly used in JWTs. JWTKit supports the [seven registered claims](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1) defined in the JWT specification, but you can also define custom claims if needed.

> Note: In the example, `CodingKeys` are defined to map Swift property names to the JSON keys used in the JWT. This means that in the JWT the expiration claim will be named `exp` and the issuer claim will be named `iss`, as per the JWT specification.

To create a JWT with this payload, you can create a new instance of the payload and use the key collection to sign it:

```swift
let payload = TestPayload(
    expiration: .init(value: .distantFuture),
    issuer: "myapp.com"
)

let token = try await keyCollection.sign(payload)
```

This will create a token that looks like the one we showed earlier. The token is now ready to be transmitted to the other party.

## Verifying a JWT

Once you receive a JWT, you can use the key collection to verify it. Verification involves verifying the signature of the token and then checking the claims in the payload:

```swift
let verifiedPayload = try await keyCollection.verify(
    token,
    as: TestPayload.self
)
```

If the token is invalid, an error will be thrown. Otherwise, the payload will be returned and should look like the original payload you signed.

## Authentication and Authorisation Flow

JWTs are commonly used in authentication and authorisation flows in web applications. Here's a simple example of how you might use JWTKit to implement an authentication and authorisation flow in a Swift project:
1. When a user logs in, for example by providing their username and password, you create a JWT with the user's information and sign it with a key.
2. You send the JWT to the client, which stores it in a secure location, such as the keychain.
3. When the client makes a request to the server, it includes the JWT in the request headers.
4. The server validates the JWT using the key collection and optionally checks the claims in the payload.
5. If the JWT is valid, the server responds to the request with the requested data.

This flow allows you to securely transmit information between the client and server without the need for the client to store sensitive information, such as passwords, locally.

Let's put this into practice with a simple example. The following snippets use Swift pseudo-code to demonstrate the flow, without using a specific web framework. You can adapt this code to work with your preferred web framework.
First, we'll create a payload struct that contains the user's information:

```swift
struct UserPayload: JWTPayload {
    let userID: Int
    let expiration: ExpirationClaim
    let roles: RoleClaim

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case expiration = "exp"
        case roles
    }

    func verify(using key: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
        try roles.verifyAdmin()
    }

    init(from user: User) {
        self.userID = user.id
        self.expiration = .init(value: .init(timeIntervalSinceNow: 3600))  // Token expires in 1 hour
        self.roles = user.roles
    }
}
```

The `UserPayload` struct represents the claims we want to include in the JWT. In this snippet, we include the user's ID, an expiration claim, and a list of roles.
The ``JWTPayload/verify(using:)`` method checks that the token has not expired and that the user is an admin. The `init` method creates a new payload from a `User` object, which could be retrieved from a database, for example.
The roles claim is a custom claim:

```swift
struct RoleClaim: JWTClaim {
    var value: [String]

    func verifyAdmin() throws {
        guard value.contains("admin") else {
            throw JWTError.claimVerificationFailure(
                failedClaim: self,
                reason: "User is not an admin"
            )
        }
    }
}
```

This is a simple struct that conforms to the ``JWTClaim`` protocol. The ``JWTClaim/value`` property is the value of the claim, which in this case is a list of roles.
Next, we'll create a route that handles user logins and returns a JWT:

```swift
struct UserPayload: JWTPayload {
    let userID: Int
    let expiration: ExpirationClaim
    let roles: RoleClaim

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case expiration = "exp"
        case roles
    }

    func verify(using key: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
        try roles.verifyAdmin()
    }

    init(from user: User) {
        self.userID = user.id
        self.expiration = .init(value: .init(timeIntervalSinceNow: 3600))  // Token expires in 1 hour
        self.roles = user.roles
    }
}
```

The `UserPayload` struct represents the claims we want to include in the JWT. In this example, we include the user's ID, an expiration claim, and a list of roles. The ``JWTPayload/verify(using:)`` method checks that the token has not expired and that the user has the "admin" role. The `init` method creates a new payload from a `User` object, which could be retrieved from a database, for example.

```swift
router.post("login") { req async throws -> Response in
    let user = User.find(username: req.body.username) // Find user by username, in a DB for example
    try user.verifyPassword(req.body.password)
    let payload = UserPayload(from: user)
    let token = try await keyCollection.sign(payload)
    return Response(status: .ok, body: token)
}
```

The `login` route receives the user's username and password, finds the user in the database, verifies the password, creates a JWT with the user's information, and signs it with the key collection. The token is then returned to the client.

Next, we'll create a route that handles requests that require authentication. This route will validate the JWT in the request headers and return the requested data if the token is valid:

```swift
router.get("admin-protected") { req async throws -> Response in
    let token = req.headers["Authorization"]
    let payload = try await keyCollection.verify(token, as: UserPayload.self)
    let user = User.find(payload.userID)
    return Response(status: .ok, body: user)
}
```

Usually web frameworks such as Vapor and Hummingbird provide middleware to handle authentication and authorisation, so you don't have to manually validate the JWT in each route. However, this example is framework-agnostic and demonstrates the basic flow of how JWTs can be used to secure your Swift projects.

This should be enough to understand how JWTKit can be used to implement an authentication and authorisation flow in your Swift projects. You can adapt this example to work with your preferred web framework and add additional features as needed.

## Conclusion

JWTKit is a powerful library for working with JSON Web Tokens in Swift. It provides a simple and easy-to-use API for creating, parsing, and validating JWTs, making it easy to implement authentication and authorisation flows in your Swift projects. In this tutorial, you learned how to install JWTKit, create and validate JWTs, and implement an authentication and authorisation flow using JWTs. While this tutorial covered the basics of JWTKit, there are many more features and options available in the library. Check out the [JWTKit README](https://github.com/vapor/jwt-kit) for more information on how to use JWTKit in your projects.

But for now, you should be able to start using JWTs in your Swift projects with confidence!
