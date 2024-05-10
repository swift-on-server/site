import Foundation

struct Sitemap {
    let config: Config
    let items: [SitemapTemplate.Item]
    let outputUrl: URL

    func generate() throws {
        let sitemapTemplate = SitemapTemplate(
            items: items
        )

        let sitemapUrl =
            outputUrl
            .appendingPathComponent("sitemap")
            .appendingPathExtension("xml")

        try sitemapTemplate.render()
            .write(
                to: sitemapUrl,
                atomically: true,
                encoding: .utf8
            )
    }
}
