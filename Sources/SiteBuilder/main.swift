#if os(macOS)
import Foundation
import Yams
import Mustache

let fs = FileManager.default
let accountId = ProcessInfo.processInfo.environment["ACCOUNT_ID"] ?? "4296918970"
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]!
let baseUrl = ProcessInfo.processInfo.environment["BASE_URL"] ?? "/"

let cwd = URL(filePath: fs.currentDirectoryPath)
let docs = cwd.appending(components: "Sources", "__SwiftOnServer_org", "Documentation.docc")
let templates = cwd.appending(components: "src", "templates")
let output = cwd.appending(components: "docs")
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy/MM/dd"
let postTemplate = try MustacheTemplate(
    string: String(contentsOf: templates.appending(components: "post.html"))
)
let indexTemplate = try MustacheTemplate(
    string: String(contentsOf: templates.appending(components: "index.html"))
)

// Run on tag through Github Actions
// TODO: Run Fetch tags on servera
// TODO: Trigger rebuild of docs on server

try openFolder(docs)

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
        let postHTML = postTemplate.render(metadata)
        let indexHTML = indexTemplate.render(IndexContext(
            baseUrl: baseUrl,
            title: metadata.title,
            description: metadata.description,
            permalink: "https://swiftonserver.com/",
            contents: postHTML
        ))
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
    let contents: String
}

struct ArticleMetadata: Codable {
    let slug: String
    let title: String
    let description: String
    let date: String
    let tags: String
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
        "https://api.swiftinit.org/render/swift-nio/niocore/swift-concurrency?account=\(accountId)&api_key=\(apiKey)",
        "-o",
        "\(folderName).html"
    ]
    try process.run()
    process.waitUntilExit()
}
#endif
