// snippet.hide
import Foundation

// This is stubbed since UIImage isn't available on mac and Linux
struct UIImage {}

func fetchImage(
    at url: URL,
    callback: @escaping (Result<UIImage, Error>) -> Void
) {
    callback(.success(UIImage()))
}
// snippet.show
final class ImageCache {
    private var cache: [URL: UIImage] = [:]
    private let lock = NSLock()

    func image(for url: URL) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache[url]
    }

    func loadImage(for url: URL) {
        lock.lock()
        defer { lock.unlock() }
        // This is covered by the lock
        if cache.keys.contains(url) {
            return
        }
        fetchImage(at: url) { [self] image in
            guard case .success(let image) = image else { return }
            // This is not covered by the lock
            cache[url] = image
        }
    }
}
