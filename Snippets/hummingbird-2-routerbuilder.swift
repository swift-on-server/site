import Hummingbird
import HummingbirdRouter

let router = RouterBuilder(context: BasicRouterRequestContext.self) {
    TracingMiddleware()
    Get("test") { _, context in
        return context.endpointPath
    }
    Get { _, context in
        return context.endpointPath
    }
    Post("/test2") { _, context in
        return context.endpointPath
    }
}
let app = Application(responder: router)
try await app.runService()
