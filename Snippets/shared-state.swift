import Foundation

// snippet.sharedState
final class SharedState: @unchecked Sendable {
    private var _state: Int = 0
    let lock = NSLock()
    public var state: Int {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _state = newValue
        }
    }
}
// snippet.end
// snippet.bankAccount
actor BankAccount {
    var balance: Int = 0

    func deposit(_ amount: Int) {
        balance += amount
    }

    func withdraw(_ amount: Int) {
        balance -= amount
    }
}

let bankAccount = BankAccount()
await bankAccount.deposit(100)
let balance = await bankAccount.balance
print(balance) // 100
// snippet.end
// snippet.unownedExecutor
_ = bankAccount.unownedExecutor
// snippet.end
struct BookOrder: Identifiable {
    let id = UUID()
    let book: Book

    func delivery() async throws -> Book {
        // Delivery takes time!!
        try await Task.sleep(for: .seconds(1))
        return book
    }
}

struct Book {}

func fetchBooks(page: Int) async throws -> [Book] {
    // No books, this is just a demo
    return []
}

// snippet.bookStore
actor BookStore: AsyncSequence {
    typealias AsyncIterator = AsyncThrowingStream<Book, Error>.AsyncIterator
    typealias Element = Book

    private var page = 1
    private var hasReachedEnd = false
    private let stream: AsyncThrowingStream<Book, Error>
    private let continuation: AsyncThrowingStream<Book, Error>.Continuation

    init() {
        (stream, continuation) = AsyncThrowingStream.makeStream(
            bufferingPolicy: .unbounded
        )
    }

    func produce() async throws {
        do {
            while !hasReachedEnd {
                let books = try await fetchBooks(page: page)
                hasReachedEnd = books.isEmpty
                for book in books {
                    continuation.yield(book)
                }
                page += 1
            }
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }

    // AsyncSequence required a nonisolated func here
    nonisolated func makeAsyncIterator() -> AsyncIterator {
        stream.makeAsyncIterator()
    }
}
// snippet.end
// snippet.bankAccountProtocol
protocol BankAccountProtocol {
    var balance: Int { get async }
    func deposit(_ amount: Int) async
    func withdraw(_ amount: Int) async
}

actor MyBankAccount: BankAccountProtocol {
    var balance: Int = 0

    func deposit(_ amount: Int) {
        balance += amount
    }

    func withdraw(_ amount: Int) {
        balance -= amount
    }
}
// snippet.end

import Foundation
struct UIImage {}

// snippet.imageCache
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? {
        return cache[url]
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
    }

    func loadImage(for url: URL) async throws {
        if cache.keys.contains(url) {
            return
        }

        let image = try await fetchImage(at: url)
        setImage(image, for: url)
    }
}
// snippet.end

// snippet.loadingAwareImageCache
actor LoadingAwareImageCache {
    private var cache: [URL: UIImage] = [:]
    private var loadingURLs: Set<URL> = []

    func image(for url: URL) -> UIImage? {
        return cache[url]
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
    }

    func loadImage(for url: URL) async throws {
        if cache.keys.contains(url), !loadingURLs.contains(url) {
            return
        }

        loadingURLs.insert(url)
        defer { loadingURLs.remove(url) }
        let image = try await fetchImage(at: url)
        setImage(image, for: url)
    }
}
// snippet.end
// snippet.findImages
func findImages(
    onImage: @Sendable (UIImage) -> Void,
    onCompletion: @Sendable (Error?) -> Void
) {
    // No actual images found, just for demonstration of the below code
    onCompletion(nil)
}
// snippet.end

// snippet.captureGroups
let (stream, continuation) = AsyncThrowingStream<UIImage, Error>.makeStream()

// Hypothetical function that lists images
// Calls the callback once for each image found
findImages { [continuation] image in
    // Captures `continuation`
    continuation.yield(image)
} onCompletion: { [continuation] error in
    // Captures `continuation`
    // Called exactly once when done or failed
    if let error = error {
        continuation.finish(throwing: error)
    } else {
        continuation.finish()
    }
}

for try await image in stream {
    // Show image
    print(image)
}
// snippet.end
func fetchImage(
    at url: URL,
    callback: @Sendable (Result<UIImage, Error>) -> Void
) {
    callback(.success(UIImage()))
}
// snippet.continuations
@Sendable func fetchImage(at url: URL) async throws -> UIImage {
    return try await withCheckedThrowingContinuation { continuation in
        fetchImage(at: url) { result in
            switch result {
            case .success(let image):
                continuation.resume(returning: image)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
// snippet.end
// snippet.efficientImageCache
actor EfficientImageCache {
    private var cache: [URL: UIImage] = [:]
    private var loadingURLs: Set<URL> = []
    private var fetchingURLs: [(URL, CheckedContinuation<UIImage, Error>)] = []
    private func completeFetchingURLs(with result: Result<UIImage, Error>, for url: URL) {
        for (awaitingURL, continuation) in fetchingURLs where awaitingURL == url {
            switch result {
            case .success(let image):
                continuation.resume(returning: image)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
        fetchingURLs.removeAll { $0.0 == url }
    }

    func setImage(_ image: UIImage, for url: URL) {
        self.cache[url] = image
    }

    func loadImage(at url: URL) async throws -> UIImage {
        if let image = cache[url] {
            return image
        }

        if loadingURLs.contains(url) {
            return try await withCheckedThrowingContinuation { continuation in
                fetchingURLs.append((url, continuation))
            }
        }

        loadingURLs.insert(url)
        defer { loadingURLs.remove(url) }

        do {
            let image = try await fetchImage(at: url)
            setImage(image, for: url)
            completeFetchingURLs(with: .success(image), for: url)
            return image
        } catch {
            completeFetchingURLs(with: .failure(error), for: url)
            throw error
        }
    }
}
// snippet.end
// snippet.globalActor
@globalActor actor SensorActor {
    static let shared = SensorActor()
}
// snippet.end
