import Dispatch

// snippet.dispatchGlobal
DispatchQueue.global().async {
    // Offload some (heavy) work
}
// snippet.end

import Foundation
// This is stubbed since UIImage isn't available on mac and Linux
struct UIImage {
    let data: Data

    init?(data: Data) {
        self.data = data
    }
}

enum NetworkError: Error {
    case missingImage
}

// snippet.fetchImageCallback
func fetchImage(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error {
            completion(.failure(error))
            return
        }
        guard let data = data, let image = UIImage(data: data) else {
            completion(.failure(NetworkError.missingImage))
            return
        }
        completion(.success(image))
    }
}
// snippet.end
