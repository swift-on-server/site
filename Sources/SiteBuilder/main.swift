#if os(macOS)
import Foundation
import Yams
import Mustache

let fs = FileManager.default
let repoId = "joannis.swiftonserver-site"
let module = "__SwiftOnServer_org"

let accountId = ProcessInfo.processInfo.environment["ACCOUNT_ID"] ?? "4296918970"
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]!

let title = ProcessInfo.processInfo.environment["SITE_TITLE"] ?? "Swift on Server"
let description = ProcessInfo.processInfo.environment["SITE_DESC"] ?? "Articles about server-side Swift development. Created by Joannis Orlandos and Tibor Bödecs."
let baseUrl = ProcessInfo.processInfo.environment["BASE_URL"] ?? "/"

let cwd = URL(filePath: fs.currentDirectoryPath)
let docs = cwd.appending(components: "Sources", module, "Documentation.docc")
let templates = cwd.appending(components: "src", "templates")
let output = cwd.appending(components: "docs")

let postDateFormatter = DateFormatter()
postDateFormatter.timeZone = .init(secondsFromGMT: 0)
postDateFormatter.dateFormat = "yyyy/MM/dd"
let postTemplate = try MustacheTemplate(
    string: String(contentsOf: templates.appending(components: "post.html"))
)
let indexTemplate = try MustacheTemplate(
    string: String(contentsOf: templates.appending(components: "index.html"))
)

struct Config {
    let baseUrl: String
    let title: String
    let description: String
    let language: String

    var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

let config = Config(
    baseUrl: baseUrl,
    title: title,
    description: description,
    language: "en-US"
)

var posts = [RSSTemplate.Item]()
var pages: [SitemapTemplate.Item] {
    posts.map {
        SitemapTemplate.Item(
            permalink: $0.permalink,
            date: $0.date
        )
    }
}

// Run on tag through Github Actions
// TODO: Run Fetch tags on servera
// TODO: Trigger rebuild of docs on server

try openFolder(docs)

try RSS(
    config: config,
    posts: posts,
    outputUrl: output
).generate()

try Sitemap(
    config: config,
    items: pages,
    outputUrl: output
).generate()

func openFolder(_ folder: URL) throws {
    let folderName = folder.lastPathComponent
    let items = try fs.contentsOfDirectory(atPath: folder.relativePath)
    if items.contains("\(folderName).md") && items.contains("metadata.yml") {
        if items.contains("\(folderName).html") {
            print("Skipping \(folderName) as it is already rendered. Remove the render to allow rerendering.")
        } else {
            print("Rendering \(folderName)...")
            try buildTutorial(folder)
            print("Rendering of \(folderName) was completed.")
        }
        
        guard var metadata = getMetadata(forFolder: folder) else {
            return
        }

        metadata.contents = try String(contentsOf: folder.appending(components: "\(folderName).html"))
        metadata.tagList = metadata.tags.split(separator: ",").map { tag in
            tag.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let permalink = "https://swiftonserver.com/\(metadata.slug)"
        let postHTML = postTemplate.render(metadata)
        let indexHTML = indexTemplate.render(IndexContext(
            baseUrl: baseUrl,
            title: metadata.title,
            description: metadata.description,
            permalink: permalink,
            image: "images/assets/\(metadata.slug)/cover.jpg",
            contents: postHTML
        ))
        if let date = postDateFormatter.date(from: metadata.date) {
            posts.append(
                RSSTemplate.Item(
                    title: metadata.title,
                    description: metadata.description,
                    permalink: permalink,
                    date: date
                )
            )
        }
        try indexHTML.write(
            to: output.appending(components: metadata.slug, "index.html"),
            atomically: true,
            encoding: .utf8
        )
    } else {
        for item in items {
            let itemURL = folder.appending(components: item)
            do {
                try openFolder(itemURL)
            } catch {
                print("Error while discovering folder at \"\(itemURL.relativePath)\": \(error)")
            }
        }
    }
}

struct IndexContext: Codable {
    let baseUrl: String
    let title: String
    let description: String
    let permalink: String
    let image: String
    let contents: String
}

struct ArticleMetadata: Codable {
    let slug: String
    let title: String
    let description: String
    let date: String
    let tags: String
    var tagList: [String]?
    let author: String
    let authorLink: String
    let authorGithub: String
    let authorAbout: String
    let cta: String
    let ctaLink: String
    let company: String
    let companyLink: String
    let duration: String
    var contents: String?
}

func getMetadata(forFolder folder: URL) -> ArticleMetadata? {
    do {
        let data = try Data(contentsOf: folder.appending(components: "metadata.yml"))
        return try YAMLDecoder().decode(ArticleMetadata.self, from: data)
    } catch {
        print("Error parsing YAML for \(folder.relativePath): \(error)")
        return nil
    }
}

func buildTutorial(_ folder: URL) throws {
    let folderName = folder.lastPathComponent
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
    process.currentDirectoryURL = folder
    process.arguments = [
        "--http2",
        "-v",
        "https://api.swiftinit.org/render/\(repoId)/\(module)/\(folder.lastPathComponent)?account=\(accountId)&api_key=\(apiKey)",
        "-o",
        "\(folderName).html"
    ]
    try process.run()
    process.waitUntilExit()
}
#endif
