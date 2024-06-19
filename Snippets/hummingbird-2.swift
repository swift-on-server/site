import Foundation
import Hummingbird
import Logging
import NIOCore

// snippet.requestDecoder
// 1.
struct MyRequestDecoder: RequestDecoder {
    func decode<T>(
        _ type: T.Type,
        from request: Request,
        context: some RequestContext
    ) async throws -> T where T: Decodable {
        // 2.
        guard let header = request.headers[.contentType] else {
            throw HTTPError(.badRequest)
        }
        // 3.
        guard let mediaType = MediaType(from: header) else {
            throw HTTPError(.badRequest)
        }
        // 4.
        let decoder: RequestDecoder
        switch mediaType {
        case .applicationJson:
            decoder = JSONDecoder()
        case .applicationUrlEncoded:
            decoder = URLEncodedFormDecoder()
        default:
            throw HTTPError(.badRequest)
        }
        // 5
        return try await decoder.decode(
            type,
            from: request,
            context: context
        )
    }
}
// snippet.end
// snippet.requestContext
// 1.
protocol MyRequestContext: RequestContext {
    var myValue: String? { get set }
}

// 2.
struct MyBaseRequestContext: MyRequestContext {
    var coreContext: CoreRequestContextStorage

    // 3.
    var myValue: String?

    init(source: Source) {
        self.coreContext = .init(source: source)
    }

    // 4.
    var requestDecoder: RequestDecoder {
        MyRequestDecoder()
    }
}
// snippet.end
struct MyModel: ResponseCodable {
    let title: String
}
// snippet.controller
struct MyController<Context: MyRequestContext> {
    // 1.
    func addRoutes(
        to group: RouterGroup<Context>
    ) {
        group
            .get(use: list)
            .post(use: create)
    }

    // 2.
    @Sendable
    func list(
        _ request: Request,
        context: Context
    ) async throws -> [MyModel] {
        [
            .init(title: "foo"),
            .init(title: "bar"),
            .init(title: "baz"),
        ]
    }

    @Sendable
    func create(
        _ request: Request,
        context: Context
    ) async throws -> EditedResponse<MyModel> {
        // 3.
        // context.myValue
        let input = try await request.decode(
            as: MyModel.self,
            context: context
        )
        return .init(status: .created, response: input)
    }
}
// snippet.end
// snippet.buildApp
func buildApplication() async throws -> some ApplicationProtocol {
    // 1.
    let router = Router(context: MyBaseRequestContext.self)

    // 2
    router.middlewares.add(LogRequestsMiddleware(.info))
    router.middlewares.add(FileMiddleware())
    router.middlewares.add(CORSMiddleware(
        allowOrigin: .originBased,
        allowHeaders: [.contentType],
        allowMethods: [.get, .post, .delete, .patch]
    ))

    // 3
    router.get("/health") { _, _ -> HTTPResponse.Status in
            .ok
    }

    // 4.
    MyController().addRoutes(to: router.group("api"))

    // 5.
    return Application(
        router: router,
        configuration: .init(
            address: .hostname("localhost", port: 8080)
        )
    )
}
// snippet.end
// snippet.run
import ArgumentParser
import Hummingbird

@main
struct HummingbirdArguments: AsyncParsableCommand {
    func run() async throws {
        let app = try await buildApplication()
        try await app.runService()
    }
}
// snippet.end
