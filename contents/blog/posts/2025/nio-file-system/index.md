---
title: "Practical Guide to Working with the SwiftNIO File System"
description: "Learn SwiftNIO's async file system API for non-blocking operations, including file and directory handling, reading, writing, and advanced use cases."
image: ./assets/cover.jpg
publication: "2025/09/03 9:00:00"
featured: true
tags:
    - server
authors:
    - tibor-bodecs
---

# Practical Guide to Working with the SwiftNIO File System ￼

The SwiftNIO package serves as the backbone for many server-side Swift projects. When most people hear about SwiftNIO, they immediately think of servers or network protocols.

However, SwiftNIO also includes a lesser-known library: a modern, async-friendly file system API. Unlike the traditional FileManager, this API allows you to read, write, and manage files without blocking threads—making it ideal for server environments.

This article covers the essentials: how to set up the file system module, create files, read and write data, work with directories, and explore a few advanced techniques.

## Setting up NIO File System

The file system APIs are part of the `_NIOFileSystem` product, which is still considered experimental. The underscore in the module name shows that the API may change in the future, but it is already extremely useful and quite stable.

Before you can use the SwiftNIO file system API, you need to add `swift-nio` as a dependency to your Swift package. Here’s how to add `_NIOFileSystem` to your `Package.swift` file:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Example",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-nio", 
            from: "2.86.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(
                    name: "_NIOFileSystem", 
                    package: "swift-nio"
                ),
            ]
        ),
    ]
)
```

Once your package manifest is set up, you can begin using the file system module in your code.

## Basic File Operations

To begin, let’s explore some basic file operations.

Most file operations are handled by the `FileSystem` struct, which offers a shared instance you can use in most situations. Another helpful tool is the `FilePath` object, which lets you build file paths safely.

Here’s how you can create a file and write a string to it:

```swift
import _NIOFileSystem

let fs = FileSystem.shared
var tmpPath = try await fs.temporaryDirectory
let filePath = tmpPath.appending("hello.txt")
let contents = "Hello, Swift NIO file system!"

let bytesWritten = try await contents.write(
    toFileAt: filePath,
    options: .modifyFile(createIfNecessary: true)
)
print("Bytes written: \(bytesWritten)")
```

In this example, you fetch the system’s temporary directory and build a file path by appending the filename you want.

Next, you write a string to the file using the async `write` method. The `.modifyFile(createIfNecessary: true)` option ensures the file is created if it does not already exist. The `write` method returns the number of bytes written, so you can confirm the operation succeeded.

You can also check if a file exists or get details like its type or size. SwiftNIO gives you a simple way to access this information:

```swift
if let info = try await fs.info(forFileAt: filePath) {
    print("Type: \(info.type)") 
    print("Size: \(info.size)")
} 
```

When you call `info`, you get details such as the file’s type, size, last modification date, permissions, and more. Use the `type` property to check if the path points to a regular file, directory, symlink, or other types like a socket.

Always check your paths before running operations or set options to modify or create files if needed. If you don’t, the file system library will throw errors.

Copying and removing files or directories are basic tasks in many applications. SwiftNIO gives you async methods to handle these operations and makes it easy to manage files and clean up resources. Here’s how you copy a file:

```swift
let copyPath = try await tmpPath.appending("copy.txt")
try await fs.copyItem(
    at: filePath, 
    to: copyPath
)
print("File copied to: \(copyPath)")
```

You can also move an item in a single operation when the operating system supports it as an underlying syscall:

```swift
let movePath = try await tmpPath.appending("moved.txt")
try await fs.moveItem(
    at: filePath, 
    to: movePath
)
print("File moved to: \(movePath)")
```

Here’s how you can delete a file when you no longer need it:

```swift
let removed = try await fs.removeOneItem(at: filePath)
print("File removed: \(removed)")
```

These operations let you handle basic file-level tasks. Now, let’s turn to working with directories.

## Listing Directories

Listing the contents of a directory is a common task, and SwiftNIO makes it simple with async sequences. Use a `FileSystem` instance to get a directory handle, then call `listContents` on the handle to loop through the entries.

Here’s an example that prints the names of all entries in a directory:

```swift
let dirPath = FilePath("/path/to/dir")

// check if path is a directory
let info = try await fs.info(forFileAt: dirPath)
if let info, info.type == .directory {
    // get directory handle and list contents
    try await fs.withDirectoryHandle(
        atPath: dirPath
    ) { dir in
        for try await entry in dir.listContents() {
            print("Item: \(entry.name)")
        }
    }
}
else {
    print("Path is not a valid directory.")
}
```

This code checks if the path is a directory and prints each entry inside. You can quickly adjust this approach to list only files, skip hidden items, or work recursively.

To list only files and not directories, add a `where` condition in the for loop:

```swift
try await fs.withDirectoryHandle(
    atPath: dirPath
) { dir in
    for try await entry in dir.listContents() where 
        entry.type != .directory 
    {
        print("Item: \(entry.name)")
    }
}
```

To list only non-hidden directories (on macOS, file names starting with a dot are hidden), add a filter using the name property:

```swift
try await fs.withDirectoryHandle(
    atPath: dirPath
) { dir in
    for try await entry in dir.listContents() where
        entry.type == .directory &&
        !entry.name.string.hasPrefix(".")
    {
        print("Item: \(entry.name)")
    }
}
```

You can also list the contents of a directory recursively. When there are many items, batching helps improve performance and reduces memory usage:

```swift
try await fs.withDirectoryHandle(
    atPath: dirPath
) { dir in
    let batches = dir.listContents(
        recursive: true
    ).batched()

    for try await batch in batches  {
        for entry in batch {
            print("Item: \(entry.name)")
        }
    }
}
```

Always check that the path exists and is a directory before you get a directory handle and list its contents.

## File Reading and Writing

SwiftNIO lets you write and read data from files using strings, byte arrays, or async sequences.

Here’s how you can write a string to a file and then read it back:

```swift
try await "Some text".write(
    toFileAt: filePath,
    options: .modifyFile(createIfNecessary: true)
)

let text = try await String(
    contentsOf: filePath,
    maximumSizeAllowed: .bytes(1024)
)
print("Read text: \(text)")
```

You can also use byte arrays, which are useful when you need to work with binary data:

```swift
let data: [UInt8] = [1, 2, 3, 4, 5]
try await data.write(
    toFileAt: filePath,
    options: .modifyFile(createIfNecessary: true)
)
let readData = try await Array(
    contentsOf: filePath,
    maximumSizeAllowed: .bytes(1024)
)
print("Read bytes: \(readData)")
```

When working with large files or tasks that need high performance, buffered readers and writers are helpful because they process data in chunks. This approach lowers memory usage and speeds up operations. 

SwiftNIO includes buffered writer and reader types that work smoothly with async/await. 

Here is an example of how to write a large amount of data using a buffered writer:

```swift
try await fs.withFileHandle(
    forReadingAndWritingAt: filePath,
    options: .newFile(replaceExisting: true)
) { file in
    var writer = file.bufferedWriter(
        capacity: .bytes(4096)
    )
    try await writer.write(
        contentsOf: repeatElement(42, count: 1000)
    )
    try await writer.flush()
}
```

Here is how you can read data in buffered chunks:

```swift
try await fs.withFileHandle(forReadingAt: path) { file in
    var reader = file.bufferedReader(
        capacity: .bytes(4096)
    )
    let bytes = try await reader.read(.bytes(1000))
    print("Read: \(bytes.readableBytes) bytes")
}
```

Buffered reading and writing is very helpful when you need to work with files that are too large to fit into memory all at once. For more advanced cases, you can use `AsyncStream` to stream data into files efficiently. 

Here is an example of how to write a stream of bytes to a file:

```swift
let stream = AsyncStream(UInt8.self) { continuation in
    for byte in 0..<64 {
        continuation.yield(UInt8(byte))
    }
    continuation.finish()
}

let bytesWritten = try await stream.write(
    toFileAt: path,
    options: .modifyFile(
        createIfNecessary: true
    )
)
print("Streamed bytes written: \(bytesWritten)")
```

This approach is great for apps that create data as they run or need to handle streaming input from other sources. By using async sequences, you can write data as it arrives without blocking your application. 

The next snippet demonstrates how to construct an `AsyncThrowingStream` that yields byte chunks and then use `FileChunks` to consume them. The sample stream is manually fed with three `ByteBuffer` values, each containing a small array of bytes. Calling `finish()` marks the end of the sequence, so no more values can be yielded afterward:

```swift
let stream = AsyncThrowingStream<ByteBuffer, Error> {
    $0.yield(ByteBuffer(bytes: [0, 1, 2]))
    $0.yield(ByteBuffer(bytes: [3, 4, 5]))
    $0.yield(ByteBuffer(bytes: [6, 7, 8]))
    $0.finish()
}

let fileChunks = FileChunks(wrapping: stream)
var iterator = fileChunks.makeAsyncIterator()

while let chunk = try await iterator.next() {
    print("Received chunk:", chunk)
}
```

Here the while let loop keeps awaiting values from the stream until `next()` yields `nil`. This makes it easier to process streams of arbitrary length and keeps the iteration logic clear and concise. It’s a natural fit for handling file or network data chunk by chunk.

## Symbolic Links

Symbolic links are common in many file systems, and SwiftNIO makes it simple to create and inspect them. You can easily create a symlink that points to another file and then check where it leads.

Here is a straightforward example of creating and inspecting a symbolic link:

```swift
let linkPath = try await tmpPath.appending("link.lnk")
try await fs.createSymbolicLink(
    at: linkPath, 
    withDestination: filePath
)
let destination = try await fs.destinationOfSymbolicLink(
    at: linkPath
)
print("Symlink points to: \(destination)")
```

This code creates a symbolic link and then prints the path it points to.


## Summary

SwiftNIO’s file system API adds async/await to file and directory operations, making them flexible and efficient. You can create, write, read, and manage files and directories, work with symbolic links, and handle advanced streaming tasks—all with clear, non-blocking code. 

If you want solid file system tools for your app but prefer not to rely on the larger Foundation framework, you should consider using the NIO file system module. By following these examples, you can quickly add strong file system features to your Swift applications.
