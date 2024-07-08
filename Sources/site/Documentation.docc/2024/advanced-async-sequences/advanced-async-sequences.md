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

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "iterateSequence")

Swift uses some syntax sugar in the above example, and unwinds that code behind the scenes:

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "unwrappedSequenceIterator")

The ``IteratorProtocol/next()`` function returns the Element as an ``Optional``. The sequence ends when the 'next' element is `nil`.

While Sequences commonly represent a collection of elements, there's no hard requirement that a sequence does so. In fact, a sequence doesn't even need to be _finite_. You could implement a random number generator that indefinitely outputs new random numbers when iterated upon.

## AsyncSequences

``AsyncSequence``s work very similarly to ``Sequence``, in that they create an iterator that has a `next` function. Unlike Sequence, an AsyncSequence uses ``AsyncIteratorProtocol``, which is created in ``AsyncSequence.makeAsyncIterator()``. The iterator returns its ``AsyncIteratorProtocol/next()`` result asynchronously as well, using structured concurrency.

This enables the following syntax:

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "iterateAsyncSequence")

This unwinds to the following code:

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "unwrappedAsyncSequenceIterator")

The simplest AsyncSequence you can create is ``AsyncStream``, which we'll cover later.

### Throwing Async Iterators

Unlike IteratorProtocol, an ``AsyncIteratorProtocol`` has another big trick up its sleeve!

An AsyncIterator can `throw` errors from the ``AsyncIteratorProtocol/next()`` function. In addition to returning `nil`, a sequence can end when it throws an error.
This is extremely helpful for using an AsyncSequence in networking operations - which can encounter errors in addition to being async calls.

The throwing counterpart to ``AsyncStream`` is ``AsyncThrowingStream``, which we'll also cover later.
You can iterate over throwing async sequences in a similar way to non-throwing async sequences:

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "iterateAsyncThrowingSequence")

Some libraries such as [MongoKitten](https://github.com/orlandos-nl/MongoKitten) use a throwing ``AsyncSequence`` to provide a stream of documents from a MongoDB collection. Since network errors can occur at any point, these errors are thrown from the iterator.

## Using AsyncStream

The simplest way to create an ``AsyncSequence`` is to use ``AsyncStream``. This is a stream of elements that you can append to, and iterate over. The main way to create an ``AsyncSequence`` is to use the static ``AsyncStream/makeStream(of:bufferingPolicy:)`` function.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "makeAsyncStream")

The two arguments of the function have a default value. `of:` specifies the type of element that this stream carries. This is currently being inferred to ``Int`` through generics.

`bufferingPolicy:` specifies how the stream should buffer elements. The default value is ``AsyncStream.Continuation.BufferingPolicy.unbounded``. This means that the stream will buffer all elements until they are consumed. If you want to limit the buffer size, you can use ``AsyncStream.Continuation.BufferingPolicy/bufferingOldest(_:)`` or ``AsyncStream.Continuation.BufferingPolicy/bufferingNewest(_:)``.

You can add elements to the stream using the ``AsyncStream.Continuation/yield(_:)`` function. This mechanism is great for bridging synchronous code with async code. For example, you can use a synchronous function to generate elements, and yield them to the stream.

### Implementing AsyncStream

To create an AsyncStream, first you need to define the type of elements that the stream will carry. In this case, a custom Event is being defined.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "uievent")

After creating the stream, you can yield events to the stream. This is done by calling the `yield` function on the continuation. The follwing example shows how to yield an event when a button is tapped in SwiftUI. Note that these practices can be used in any Swift codebase, including on Linux and Windows.

```swift
struct StartDownloadView: View {
    let continuation: AsyncStream<UIEvent>.Continuation

    var body: some View {
        Button("Start Download") {
            continuation.yield(.startDownloadTapped)
        }
    }
}
```

By leveraging the structured nature of Swift's concurrency model, we can predict the behavior of our code more easily. For example, when a user taps the button twice, we can be sure that the stream will receive two events in order.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "appstate")

### Parallising Work

The main issue in the above logic is that the `startDownload` function is prevening the app from handling other UIEvents while the download is still in progress. Due to structured concurrency, your UI won't freeze, but any events are still being queued up and not executing. This can be a problem if you have multiple actions that do not interact with each other.

We can rewrite the loop using a ``DiscardingTaskGroup`` to start the download in parallel with handling other events.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "parallel")

The `downloadState` property is set to `downloading` before parallelising work. This ensures that quickly tapping the button twice can never result in two downloads happening at the same time.

## Implementing Custom AsyncSequence

You can implement your own ``AsyncSequence`` by implementing the ``AsyncSequence`` protocol. This protocol has two associated types: ``Element`` and ``AsyncIterator``. You'll need to implement the ``AsyncSequence/makeAsyncIterator()`` function and the ``AsyncIteratorProtocol``.

First we'll define our custom ``DelayedElementEmitter`` struct. This struct will emit elements from an array with a delay between each element.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "delayedelementemitter")

This struct needs an iterator and a function to construct that iterator. The iterator is not expected to be shared between multiple consumers, so it can be a struct.

Unlike a regular ``Sequence``, the ``AsyncSequence/makeAsyncIterator()`` is expected to be called only once. While structured concurrency allows calling this function multiple times, it's not expected that a sequence supports this in practice.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "delayedelementiterator")

You can now use this custom ``AsyncSequence`` in your code. The following example shows how to create a sequence that emits numbers from 1 to 5 with a delay of 1 second between each number.

@Snippet(path: "site/Snippets/advanced-async-sequences", slice: "delayedprint")

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

It is expected that Async Sequences handle cancellation gracefully as appropriate. In Networking, this could mean cancelling a network request. In a generator, this could mean stopping the generation of new elements through ``AsyncStream.Continuation.finish()``.

To detect a cancellation signal, use ``withTaskCancellationHandler(operation:onCancel:)``. Or when using Swift Service Lifecycle, use ``withTaskCancellationOrGracefulShutdownHandler(operation:onCancelOrGracefulShutdown:)``.

## Changes in Swift 6

In Swift 5, any `async` function that does not use actor isolation implicitly runs on the global concurrent executor. This means that the ``AsyncIteratorProtocol.next()`` function runs on the global concurrent executor as well.

Starting with Swift 6, a variant of this function is available.

```swift
mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Element?
```

The `isolated (any Actor)?` argument allows callees to tell an `async` function which actor the function runs on. This is helpful for performance-sensitive contexts.

Finally, Swift 6' AsyncSequences can specify an `associatedtype Failure: Error`. Using typed throws, you can specify the type of error that the iterator can throw.

```swift
mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws(Failure) -> Element?
```

By default, `throws` is equivalent to `throws(any Error)`, and this is reflected when you omit specifying a specific ``Error`` type in Failure.

## Conclusion

AsyncSequences are a cornerstone of structured concurrency in Swift. They enable you to create streams of elements that can be iterated upon asynchronously. They're especially useful in networking, but also serve great purpose in UI programming and other areas.