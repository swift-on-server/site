import FileManagerKit
import SwiftSoup
import Foundation
import Mustache
import Yams

let fileManager = FileManager.default
let env = ProcessInfo.processInfo.environment

let repoId = "swift-on-server.site:main"
let module = "site"

let accountId = env["ACCOUNT_ID"] ?? "4296918970"
let apiKey = env["API_KEY"]!

let title = env["SITE_TITLE"] ?? "Swift on Server"
let description =
    env["SITE_DESC"]
    ?? "Articles about server-side Swift development. Created by Joannis Orlandos and Tibor Bödecs."
let baseUrl = env["BASE_URL"] ?? "https://swiftonserver.com/"

let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let docs =
    cwd
    .appendingPathComponent("Sources")
    .appendingPathComponent(module)
    .appendingPathComponent("Documentation.docc")

let templates =
    cwd
    .appendingPathComponent("src")
    .appendingPathComponent("templates")

let output =
    cwd
    .appendingPathComponent("docs")

try fileManager.delete(at: output)
try fileManager.createDirectory(at: output)

let publicItems =
    cwd
    .appendingPathComponent("src")
    .appendingPathComponent("public")

for item in fileManager.listDirectory(at: publicItems) {
    if fileManager.exists(at: output.appendingPathComponent(item)) {
        continue
    }
    try fileManager.copy(
        from: publicItems.appendingPathComponent(item),
        to: output.appendingPathComponent(item)
    )
}

let postDateFormatter = DateFormatter()
postDateFormatter.timeZone = .init(secondsFromGMT: 0)
postDateFormatter.dateFormat = "yyyy/MM/dd"

let library = MustacheLibrary(templates: [
    "index": try MustacheTemplate(
        string: String(
            contentsOf: templates.appendingPathComponent("index.mustache")
        )
    ),
    "home": try MustacheTemplate(
        string: String(
            contentsOf: templates.appendingPathComponent("home.mustache")
        )
    ),
    "home-post": try MustacheTemplate(
        string: String(
            contentsOf: templates.appendingPathComponent("home-post.mustache")
        )
    ),
    "post": try MustacheTemplate(
        string: String(
            contentsOf: templates.appendingPathComponent("post.mustache")
        )
    ),
    "page": try MustacheTemplate(
        string: String(
            contentsOf: templates.appendingPathComponent("page.mustache")
        )
    ),
    "404": try MustacheTemplate(
        string: String(
            contentsOf: templates.appendingPathComponent("404.mustache")
        )
    ),
])

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

var posts: [RSSTemplate.Item] = []
var pages: [SitemapTemplate.Item] = []

// Run on tag through Github Actions
// TODO: Run Fetch tags on server
// TODO: Trigger rebuild of docs on server

try openFolder(docs)
posts.sort(by: { $0.date > $1.date })

try RSS(
    config: config,
    posts: posts,
    outputUrl: output
)
.generate()

try Sitemap(
    config: config,
    items: pages,
    outputUrl: output
)
.generate()

let home = library.render(
    IndexContext(
        baseUrl: baseUrl,
        title: title,
        description: description,
        permalink: baseUrl,
        image: "images/defaults/defaults.png",
        contents: library.render(
            HomeContext(posts: posts),
            withTemplate: "home"
        )!
    ),
    withTemplate: "index"
)!

try home.write(
    to: output.appendingPathComponent("index.html"),
    atomically: true,
    encoding: .utf8
)

func openFolder(_ folder: URL) throws {
    let folderName = folder.lastPathComponent

    let items = fileManager.listDirectory(at: folder)
    if items.contains("\(folderName).md") && items.contains("metadata.yml") {
        
        if items.contains("\(folderName).html") {
            print(
                "Skipping \(folderName) as it is already rendered. Remove the render to allow rerendering."
            )
        }
        else {
            print("Rendering \(folderName)...")
            try buildTutorial(folder)
            print("Rendering of \(folderName) was completed.")
        }

        var metadata = try getMetadata(forFolder: folder)

        try fileManager.createDirectory(
            at: output.appendingPathComponent(metadata.slug)
        )
        
        let modificationDate = try fileManager.modificationDate(
            at: folder.appendingPathComponent("\(folderName).md")
        )

        // create assets directory
        try fileManager.createDirectory(
            at: output
                .appendingPathComponent("images")
                .appendingPathComponent("assets")
        )
        
        let imagesUrl = folder.appendingPathComponent("images")
        if fileManager.directoryExists(at: imagesUrl) {
            try fileManager.createDirectory(
                at: output
                    .appendingPathComponent("images")
                    .appendingPathComponent("assets")
                    .appendingPathComponent(metadata.slug)
            )

            try fileManager.copy(
                from: imagesUrl,
                to: output
                    .appendingPathComponent("images")
                    .appendingPathComponent("assets")
                    .appendingPathComponent(metadata.slug)
                    .appendingPathComponent("images")
            )
        }
        
        let coverUrl = folder.appendingPathComponent("cover.jpg")
        if fileManager.fileExists(at: coverUrl) {
            try fileManager.createDirectory(
                at: output
                    .appendingPathComponent("images")
                    .appendingPathComponent("assets")
                    .appendingPathComponent(metadata.slug)
            )
            try fileManager.copy(
                from: coverUrl,
                to: output
                    .appendingPathComponent("images")
                    .appendingPathComponent("assets")
                    .appendingPathComponent(metadata.slug)
                    .appendingPathComponent("cover.jpg")
            )
        }

        metadata.contents = try String(
            contentsOf: folder.appendingPathComponent("\(folderName).html")
        )
        metadata.tagList = metadata.tags.split(separator: ",")
            .map { tag in
                tag.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        let permalink = "\(baseUrl)\(metadata.slug)/"
        let postHTML = library.render(metadata, withTemplate: "post")!
        let indexHTML = library.render(
            IndexContext(
                baseUrl: baseUrl,
                title: metadata.title,
                description: metadata.description,
                permalink: permalink,
                image: "images/assets/\(metadata.slug)/cover.jpg",
                contents: postHTML
            ),
            withTemplate: "index"
        )!
        if let date = postDateFormatter.date(from: metadata.date) {
            posts.append(
                RSSTemplate.Item(
                    title: metadata.title,
                    description: metadata.description,
                    permalink: permalink,
                    date: date,
                    dateString: metadata.date
                )
            )
            pages.append(
                SitemapTemplate.Item(
                    permalink: permalink,
                    date: modificationDate as Date
                )
            )
        }

        let document: Document = try SwiftSoup.parse(indexHTML)
        try document.select(".introduction").remove()

        let outputSettings = OutputSettings()
        outputSettings.prettyPrint(pretty: false)
        outputSettings.indentAmount(indentAmount: 2)
        try document.outputSettings(outputSettings).outerHtml().write(
            to:
                output
                .appendingPathComponent(metadata.slug)
                .appendingPathComponent("index.html"),
            atomically: true,
            encoding: .utf8
        )
    } else {
        for item in items {
            let itemURL = folder.appendingPathComponent(item)
            do {
                try openFolder(itemURL)
            } catch {
                print(
                    "Error while discovering folder at \"\(itemURL.relativePath)\": \(error)"
                )
            }
        }
    }
}

struct IndexContext {
    let baseUrl: String
    let title: String
    let description: String
    let permalink: String
    let image: String?
    let contents: String
}

struct HomeContext {
    let posts: [RSSTemplate.Item]
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

func getMetadata(forFolder folder: URL) throws -> ArticleMetadata {
    let data = try Data(
        contentsOf: folder.appendingPathComponent("metadata.yml")
    )
    return try YAMLDecoder().decode(ArticleMetadata.self, from: data)
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
        "\(folderName).html",
    ]
    try process.run()
    process.waitUntilExit()
}
