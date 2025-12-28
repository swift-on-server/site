---
title: "Getting Started with Swift Package Manager"
description: "Learn how to create and manage Swift packages with SwiftPM."
image: ./assets/cover.jpg
publication: "2024/10/27 12:00:00"
tags:
    - utilities
authors:
    - joannis-orlandos
---

# Getting Started with Swift Package Manager

Swift Package Manager (SwiftPM) is a tool for managing the distribution of Swift code. It allows you to create reusable packages, and to distribute them to other developers. SwiftPM is included with Swift, and is the recommended way to distribute Swift libraries in Swift.

## What is a Swift Package?

A Swift _package_ is a collection of Swift code, resources, and other assets that can be distributed and reused in other projects. Packages can contain anything from a single file to an entire project.

Packages are made up from a few basic components:

- **Products**: A product is a collection of one or more targets, that other packages can depend on.
- **Targets**: A target is the fundamental building block of a package, and is the unit of distribution.
- **Dependencies**: A dependency is another package that is required by this package.

In addition to these components, packages have a few other characteristics:

- **Name**: The name of the package, which must be unique across all packages.
- **Platforms**: The platforms (e.g macOS 10.15, iOS 18) that it supports.

Finally, each package must have a special comment on top of the file that contains the package manifest version. That looks something along the lines of:

```swift
// swift-tools-version: 5.10
```

## Creating a Package

When creating a package, you'll need to create a `Package.swift` file and basic layout. To get set up quickly, the `swift` commandline utility has a `package` subcommand that can generate a basic package layout for you.

There are a few types of packages you can create. The most important two are:

- **executable**: Creates a (Command Line) executable target.
- **library**: Creates a library target.

To create a new _executable_ package, run the following command:

```bash
mkdir MyProject && cd MyProject
swift package init --type=executable
```

From here, you can start adding your code to the `Sources` directory, and add dependencies to the `Package.swift` file. The Package.swift file is also called the _Package Manifest_.

Let's analyze the generated `Package.swift` file:

```swift
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyProject", // 1
    // 2
    targets: [ // 3
        .executableTarget(
            name: "MyProject"
        ),
    ]
)
```

As you see, the `Package.swift` format is a simple Swift source file that defines a `Package` variable named `package`. This is compiled using Swift as well, granting access to the environment variables and other basic language tools. Package manifests are sandboxed (for good reason), so there's no filesystem or network access.

In the first marker, SwiftPM put the name of the directory as the Package's name.
Then, you'll notice a marker in empty space. This is normally where you can specify products you'd like to expose.

Executable targets don't generally need to expose themselves, as they cannot be imported like a library. As such, it is omitted.

Underneath the products section, you'll see the targets section. This is where you can define the targets that are part of this package.

## Adding Dependencies

Next, let's add a dependency to our package. Run the following command in the terminal. Make sure you run this from your SwiftPM project's directory.

```sh
swift package add-dependency https://github.com/hummingbird-project/hummingbird.git --from 2.2.0
```

If you look at your _Package Manifest_ again, you'll see that Hummingbird has been added as a dependency.

```swift
dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.2.0"),
],
```

In SwiftPM you can choose how to add a dependency. Both explicitly editing the manifest, or using the CLI tool work out the same way.

Many libraries will show you the `.package` method, which allows you to specify the dependency's URL and the version you'd like to use. However, Swift 6 introduced the command-line tool we used, so as time passes you'll likely find more and more packages using that.

Before you can `import Hummingbird` in your app, you'll need to do one more thing!

### Target Dependencies

Depending on a package is not enough to import the package's targets. You'll need to add the package's targets as dependencies to your target. Hummingbird in particular takes advantage of this structure, by allowing you to choose the parts of the library you want. This way you don't compile libraries you don't need.

```sh
swift package add-target-dependency Hummingbird MyProject
```

This will add Hummingbird as a dependency to your target. Swift will automatically understand that `Hummingbird` is a library within the hummingbird package, and will make it available to you. The second argument, MyProject, is the name of your _target_, not your package.

You'll notice that the package's target now looks like this:

```swift
.executableTarget(
    name: "MyProject",
    dependencies: [
        .target(name: "Hummingbird"),
    ]),
```

From here, you can `import Hummingbird` in your code, and start using it.

## Conclusion

In this article, we've covered the basics of Swift Package Manager. We've seen how to create a package, add dependencies, and add target dependencies.

You've learned how to add a dependency to your package, and how to add a target dependency to your target. This enables you to use Swift's wide ecosystem of packages in your project.

I highly recommend checking out the [Swift Package Index](https://swiftpackageindex.com) to find packages that might be useful for your project.
