let mySequence = [1, 2, 3]

func iterateSequence() {
    // snippet.iterateSequence
    for element in mySequence {
        print(element)
    }
    // snippet.end
}

func manuallyIterateSequence() {
    // snippet.unwrappedSequenceIterator
    var iterator = mySequence.makeIterator()
    while let element = iterator.next() {
        print(element)
    }
    // snippet.end
}

func makeAsyncStream() -> AsyncStream<Int> {
    // snippet.makeAsyncStream
    let (stream, continuation) = AsyncStream<Int>.makeStream()
    // snippet.end
    for element in mySequence {
        continuation.yield(element)
    }
    continuation.finish()
    return stream
}

enum MyError: Error {
    case someIssue
}

func makeAsyncThrowingStream() -> AsyncThrowingStream<Int, Error> {
    let (stream, continuation) = AsyncThrowingStream<Int, Error>.makeStream()
    for element in mySequence {
        continuation.yield(element)
    }
    continuation.yield(with: .failure(MyError.someIssue))
    return stream
}

func iterateAsyncSequence() async {
    let myAsyncSequence = makeAsyncStream()
    // snippet.iterateAsyncSequence
    for await element in myAsyncSequence {
        print(element)
    }
    // snippet.end
}

func manuallyIterateAsyncSequence() async {
    let myAsyncSequence = makeAsyncStream()
    // snippet.unwrappedAsyncSequenceIterator
    var iterator = myAsyncSequence.makeAsyncIterator()
    while let element = await iterator.next() {
        print(element)
    }
    // snippet.end
}

func iterateAsyncThrowingSequence() async throws {
    let myAsyncThrowingSequence = makeAsyncThrowingStream()
    // snippet.iterateAsyncThrowingSequence
    for try await element in myAsyncThrowingSequence {
        print(element)
    }
    // snippet.end
}

// snippet.uievent
// Define all UI events that a user can send
enum UIEvent: Sendable {
    case startDownloadTapped
}

// Create a stream of UI events
let (stream, continuation) = AsyncStream<UIEvent>.makeStream()
// snippet.end

continuation.yield(.startDownloadTapped)

// snippet.appstate
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
// snippet.end

extension AppState {
    func startDownload() async throws {
        // NOOP
    }
}

actor AppState2 {
    var downloadState = AppState.DownloadState.notDownloaded
    let stream: AsyncStream<UIEvent>

    init(stream: AsyncStream<UIEvent>) {
        self.stream = stream
    }

    // snippet.parallel
    func setDownloadState(_ state: AppState.DownloadState) {
        downloadState = state
    }

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
                                try await self.startDownload()
                                await self.setDownloadState(.downloaded)
                            } catch {
                                await self.setDownloadState(.notDownloaded)
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
    // snippet.end

    func startDownload() async throws {
        // NOOP
    }
}

// snippet.delayedelementemitter
struct DelayedElementEmitter<Element: Sendable>: AsyncSequence {
    let elements: [Element]
    let delay: Duration

    init(elements: [Element], delay: Duration) {
        self.elements = elements
        self.delay = delay
    }
}
// snippet.end
// snippet.delayedelementiterator
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
// snippet.end
// snipet.delayedprint
let delayedEmitter = DelayedElementEmitter(elements: [1, 2, 3, 4, 5], delay: .seconds(1))

for try await number in delayedEmitter {
    print(number)
}
// snippet.end