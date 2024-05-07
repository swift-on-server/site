#if os(macOS)
import Foundation

struct RSS {
    let config: Config
    let posts: [RSSTemplate.Item]
    let outputUrl: URL

    func generate() throws {
        let rssTemplate = RSSTemplate(
            items: posts,
            config: config
        )

        let rssUrl = outputUrl
            .appendingPathComponent("rss")
            .appendingPathExtension("xml")

        try rssTemplate.render()
            .write(
                to: rssUrl,
                atomically: true,
                encoding: .utf8
            )
    }
}
#endif
