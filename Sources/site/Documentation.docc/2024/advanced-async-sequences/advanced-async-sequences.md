# Advanced Async Sequences in Swift

``AsyncSequence``s are very prevalent in Server-Side Swift, and are becoming more prominent in macOS and iOS apps as well.

Like other structured concurrency features, AsyncSequences enable structured programming. This makes it easier for you to reason about your code, and write more robust code free of data races.

This guide assumes familiarity with Structured Concurrency as covered in these guides:

- <doc:getting-started-with-structured-concurrency-in-swift>
- <doc:structured-concurrency-and-shared-state-in-swift>

## What is a Sequence?

Swift's ``Sequence`` types are very commonly present in Swift. They provide sequential, iterated access to its elements. The most common sequence types such as ``Array``, ``Set`` and ``Dictionary`` are all a ``Collection``.

Thes Collection types can accessed by subscript, by providing an Index. The type of Index varies between implementations. A common example is the ``Int`` index used to access an ``Array``.

Whereas ``Collection`` types enable access to one or more specific elements, ``Sequence`` do not necessarily provide this capability. A Sequence solely has the ability to iterate upon a set of elements.

When you're using a `for .. in` loop to iterate elements, you're always leveraging the sequence APIs.

### IteratorProtocol

Sequence implementations only need to provide one function, the ``Sequence/makeIterator`` function. This function creates an ``IteratorProtocol`` that you implement as well.

_IteratorProtocol_ should be implemented as a `struct`, and has a single function called ``IteratorProtocol/next()``. This _mutating_ function returns the next element in the sequence.

A common way to consume sequences and iterators is the `for .. in` syntax:

```swift
for element in mySequence {
    print(element)
}
```

Swift uses some syntax sugar in the above example, and unwinds that code behind the scenes:

```swift
var myIterator = mySequence.makeIterator()
while let element = myIterator.next() {
    print(element)
}
```

The ``IteratorProtocol/next()`` function returns the Element as an ``Optional``. The sequence ends when the 'next' element is `nil`.

While Sequences commonly represent a collection of elements, there's no hard requirement that a sequence does so. In fact, a sequence doesn't even need to be _finite_. You could implement a random number generator that indefinitely outputs new random numbers when iterated upon.

## AsyncSequences

``AsyncSequence``s work very similarly to ``Sequence``, in that they create an iterator that has a `next` function. Unlike Sequence, an AsyncSequence uses ``AsyncIteratorProtocol``, which is created in ``AsyncSequence.makeAsyncIterator()``. The iterator returns its ``AsyncIteratorProtocol/next()`` result asynchronously as well, using structured concurrency.

This enables the following syntax:

```swift
for await element in myAsyncSequence {
    print(element)
}
```

This unwinds to the following code:

```swift
var myAsyncIterator = myAsyncSequence.makeIterator()
while let element = await myAsyncIterator.next() {
    print(element)
}
```

The simplest AsyncSequence you can create is ``AsyncStream``, which we'll cover later.

### Throwing Async Iterators

Unlike IteratorProtocol, an ``AsyncIteratorProtocol`` has another big trick up its sleeve!

An AsyncIterator can `throw` errors from the ``AsyncIteratorProtocol/next()`` function. In addition to returning `nil`, a sequence can end when it throws an error.
This is extremely helpful for using an AsyncSequence in networking operations - which can encounter errors in addition to being async calls.

The throwing counterpart to ``AsyncStream`` is ``AsyncThrowingStream``, which we'll also cover later.
You can iterate over throwing async sequences in a similar way to non-throwing async sequences:

```swift
for try await element in myAsyncThrowingSequence {
    print(element)
}
```

Some libraries such as [MongoKitten](https://github.com/orlandos-nl/MongoKitten) use a throwing ``AsyncSequence`` to provide a stream of documents from a MongoDB collection. Since network errors can occur at any point, these errors are thrown from the iterator.

## Using AsyncStream

The simplest way to create an ``AsyncSequence`` is to use ``AsyncStream``. This is a stream of elements that you can append to, and iterate over. The main way to create an ``AsyncSequence`` is to use the static ``AsyncStream/makeStream(of:bufferingPolicy:)`` function.

```swift
let (stream, continuation) = AsyncStream<String>.makeStream()
```

The two arguments of the function have a default value. `of:` specifies the type of element that this stream carries. This is currently being inferred to ``String`` through generics.

`bufferingPolicy:` specifies how the stream should buffer elements. The default value is ``AsyncStream.Continuation.BufferingPolicy.unbounded``. This means that the stream will buffer all elements until they are consumed. If you want to limit the buffer size, you can use ``AsyncStream.Continuation.BufferingPolicy/bufferingOldest(_:)`` or ``AsyncStream.Continuation.BufferingPolicy/bufferingNewest(_:)``.

You can add elements to the stream using the ``AsyncStream.Continuation/yield(_:)`` function. This mechanism is great for bridging synchronous code with async code. For example, you can use a synchronous function to generate elements, and yield them to the stream.

### Implementing AsyncStream

To create an AsyncStream, first you need to define the type of elements that the stream will carry. In this case, a custom Event is being defined.

```swift
// Define all UI events that a user can send
enum UIEvent: Sendable {
    case startDownloadTapped
}

// Create a stream of UI events
let (stream, continuation) = AsyncStream<UIEvent>.makeStream()
```

After creating the stream, you can yield events to the stream. This is done by calling the `yield` function on the continuation. The follwing example shows how to yield an event when a button is tapped in SwiftUI. Note that these practices can be used in any Swift codebase, including on Linux and Windows.

```swift
struct StartDownloadView: View {
    let continuation: AsyncStream<UIEvent>.Continuation

    var body: some View {
        Button("Start Download") {
            continuation.yield(.buttonTapped)
        }
    }
}
```

By leveraging the structured nature of Swift's concurrency model, we can predict the behavior of our code more easily. For example, when a user taps the button twice, we can be sure that the stream will receive two events in order.

```swift
actor AppState {
    enum DownloadState {
        case notDownloaded
        case downloading
        case downloaded
    }

    var downloadState = DownloadState.notDownloaded
    let stream: AsyncStream<UIEvent>

    init(stream: AsyncStream<UIEvent>) {
        self.stream = stream
    }

    func handleEvents() async {
        for await event in stream {
            switch event {
            case .startDownloadTapped:
                switch downloadState {
                case .notDownloaded:
                    downloadState = .downloading
                    do {
                        try await startDownload()
                        downloadState = .downloaded
                    } catch {
                        downloadState = .notDownloaded
                    }
                case .downloading, .downloaded:
                    // Don't respond to user input
                    continue
                }
            }
        }
    }
}
```

### Parallising Work

The main issue in the above logic is that the `startDownload` function is prevening the app from handling other UIEvents while the download is still in progress. Due to structured concurrency, your UI won't freeze, but any events are still being queued up and not executing. This can be a problem if you have multiple actions that do not interact with each other.

We can rewrite the loop using a ``DiscardingTaskGroup`` to start the download in parallel with handling other events.

```swift
func handleEvents() async {
    await withDiscardingTaskGroup { taskGroup in
        for await event in stream {
            switch event {
            case .startDownloadTapped:
                switch downloadState {
                case .notDownloaded:
                    downloadState = .downloading
                    taskGroup.addTask {
                        // This code runs in parallel with the loop
                        // It doesn't block the loop from handling other events
                        do {
                            try await startDownload()
                            downloadState = .downloaded
                        } catch {
                            downloadState = .notDownloaded
                        }
                    }
                case .downloading, .downloaded:
                    // Don't respond to user input
                    continue
                }
            }
        }
    }
}
```

The `downloadState` property is set to `downloading` before parallelising work. This ensures that quickly tapping the button twice can never result in two downloads happening at the same time.

## Implementing Custom AsyncSequence

You can implement your own ``AsyncSequence`` by implementing the ``AsyncSequence`` protocol. This protocol has two associated types: ``Element`` and ``AsyncIterator``. You'll need to implement the ``AsyncSequence/makeAsyncIterator()`` function and the ``AsyncIteratorProtocol``.

First we'll define our custom ``DelayedElementEmitter`` struct. This struct will emit elements from an array with a delay between each element.

```swift
struct DelayedElementEmitter<Element: Sendable>: AsyncSequence {
    let elements: [Element]
    let delay: Duration

    init(elements: [Element], delay: Duration) {
        self.elements = elements
        self.delay = delay
    }
}
```

This struct needs an iterator and a function to construct that iterator. The iterator is not expected to be shared between multiple consumers, so it can be a struct.

Unlike a regular ``Sequence``, the ``AsyncSequence/makeAsyncIterator()`` is expected to be called only once. While structured concurrency allows calling this function multiple times, it's not expected that a sequence supports this in practice.

```swift
extension DelayedElementEmitter {
    struct AsyncIterator: AsyncIteratorProtocol {
        var elements: [Element]
        let delay: Duration

        mutating func next() async throws -> Element? {
            try await Task.sleep(for: delay)
            if elements.isEmpty {
                return nil
            } else {
                return elements.removeFirst()
            }
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(
            elements: elements,
            delay: delay
        )
    }
}
```

You can now use this custom ``AsyncSequence`` in your code. The following example shows how to create a sequence that emits numbers from 1 to 5 with a delay of 1 second between each number.

```swift
let delayedEmitter = DelayedElementEmitter(elements: [1, 2, 3, 4, 5], delay: .seconds(1))

for try await number in delayedEmitter {
    print(number)
}
```

Note that our custom ``DelayedElementEmitter`` cannot be iterated upon without a `try` keyword to handle errors. This is because the ``AsyncIteratorProtocol/next()`` function can throw errors due to being marked as `throws`. We can also handle the ``CancellationError``s that ``Task.sleep(for:tolerance:clock:)`` throws in the `next()` function.

```swift
mutating func next() async -> Element? {
    do {
        try await Task.sleep(for: delay)
    } catch {
        return nil
    }

    if elements.isEmpty {
        return nil
    } else {
        return elements.removeFirst()
    }
}
```

The above change would allow you to iterate over the sequence without needing to handle errors.

### Cancellation

The ``AsyncIteratorProtocol/next()`` function can be cancelled by the consumer. This can be done through ``TaskGroup.cancelAll()``, ``Task.cancel()`` or a variety of other cancellation mechanisms.

It is expected that Async Sequences handle cancellation gracefully as appropriate. In Networking, this could mean cancelling a network request. In a generator, this could mean stopping the generation of new elements.

## Conclusion

AsyncSequences are a cornerstone of structured concurrency in Swift. They enable you to create streams of elements that can be iterated upon asynchronously. They're especially useful in networking, but also serve great purpose in UI programming and other areas.