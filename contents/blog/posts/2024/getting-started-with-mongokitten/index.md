---
title: "Getting Started with MongoKitten"
description: "Learn how to get started with MongoDB using MongoKitten"
image: ./assets/cover.jpg
publication: "2024/12/28 9:00:00"
tags:
  - databases
authors:
  - joannis-orlandos
---
# Getting Started with MongoDB in Swift using MongoKitten

[MongoDB](https://www.mongodb.com/) is a popular NoSQL database that stores data in flexible, JSON-like documents. [MongoKitten](https://github.com/orlandos-nl/MongoKitten) provides a Swift-native way to interact with MongoDB, complete with type-safe queries and Codable support.

Learn how to integrate MongoDB with your Swift application using MongoKitten. This tutorial shows you how to set up a connection, work with BSON data, and perform basic database operations.

## Setting Up MongoDB

The quickest way to get started with MongoDB is using Docker. Run this command in your terminal:

```sh
docker run --name mongodb -d -p 27017:27017 mongo:latest
```

> Note: For production environments, refer to the [official MongoDB installation guide](https://docs.mongodb.com/manual/installation/).

### Adding MongoKitten to Your Project

First, add MongoKitten to your package dependencies:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/MongoKitten.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "MongoKitten", package: "MongoKitten")
            ]
        )
    ]
)
```

## Connecting to MongoDB

Let's create our first connection:

```swift
let db = try await MongoDatabase.connect(to: "mongodb://localhost:27017/social_network")
print("Connected to MongoDB!")
```

### Defining Our Models

For our social network, we'll create a Post model using the ``Codable`` protocol:

```swift
struct Post: Codable {
    let _id: ObjectId
    let author: String
    let content: String
    let createdAt: Date
    
    init(author: String, content: String) {
        self._id = ObjectId()
        self.author = author
        self.content = content
        self.createdAt = Date()
    }
}
```

The ``ObjectId`` type is MongoDB's native unique identifier, similar to a ``UUID``. Every document in MongoDB has an `_id` field, which must be unique within a collection.

### Creating Posts

Let's create a function to save posts:

```swift
func createPost(author: String, content: String) async throws {
    // 1. Create the post
    let post = Post(author: author, content: content)
    
    // 2. Get the posts collection
    let posts = db["posts"]
    
    // 3. Insert the post
    try await posts.insertEncoded(post)
}
```

1. Create the post as a regular Swift struct
2. Access the posts ``MongoCollection``, this is similar to a table in a relational database
3. Call the ``MongoCollection.insertEncoded(_:writeConcern:)`` method to insert the post into the database. This method automatically converts the object to BSON and inserts it into the database.

In BSON, all entities are stored as '**documents**'.

### Reading Posts

To read posts, we can use MongoKitten's query API:

```swift
// 1. Find all posts
let allPosts = try await db["posts"]
    .find()
    .decode(Post.self)
    .drain()
```

All the methods are chainable, and modify the query. MongoKitten will only execute the query when you call ``MongoCursor.drain``, or iterate over the results of any query.

Before draining the query, you can also call ``QueryCursor.decode(_:using:)`` to decode the results into a specific type. This takes the database rows (documents) and decodes them into the specified ``Decodable`` type.

The drain function will execute the query and return the results as an array of the specified type.

> Note: If your dataset is large, consider streaming the results instead of using ``MongoCursor.drain``. This is more memory efficient, and allows you to process the results incrementally.

### Filtering Results

MongoKitten supports filtering and sorting on most queries.

```swift
// 2. Find posts by a specific author
let authorPosts = try await db["posts"]
    .find("author" == "swift_developer")
    .decode(Post.self)
    .drain()
```


The ``MongoCollection.find(_:) (Query)`` method returns a ``FindQueryBuilder``, a type of ``MongoCursor`` that allows you to chain more methods.

### Sorting and Limiting

```swift
// 3. Find recent posts, sorted by creation date
let recentPosts = try await db["posts"]
    .find()
    .sort(["createdAt": .descending])
    .limit(10)
    .decode(Post.self)
    .drain()
```


The **find** method accepts one argument, a filter. By providing the find filter, MongoDB will only return documents that match the filter.

Then, chain the following methods:

- ``FindQueryBuilder.sort(_:) (Sorting)`` allows you to sort the results by one or more fields.
- ``FindQueryBuilder.limit(_:)`` allows you to limit the number of results returned.

### Understanding BSON

MongoDB, and by extension MongoKitten, uses ``BSON`` (Binary JSON) as its native data format. While MongoKitten handles most BSON conversions automatically through Codable, you can also work with BSON directly:

```swift
struct Person: Codable {
    let name: String
    let age: Int
    let tags: [String]
    let active: Bool
}

// Creating a BSON Document manually
let document: Document = [
    "name": "Swift Developer",
    "age": 25,
    "tags": ["swift", "mongodb", "backend"] as Document,
    "active": true
]

// Converting between BSON and Codable
let bsonDocument = try BSONEncoder().encode(document)
let decodedPerson = try BSONDecoder().decode(Person.self, from: bsonDocument)
```


## Next Steps

You've learned the basics of working with MongoDB using MongoKitten! Here's what you can explore next:

- Advanced queries and aggregations
- Indexing for better performance
- Working with multiple collections
- Implementing authentication and authorization
- Handling relationships between documents

### Resources

- [MongoKitten Documentation](https://swiftpackageindex.com/orlandos-nl/MongoKitten/documentation/mongokitten)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
