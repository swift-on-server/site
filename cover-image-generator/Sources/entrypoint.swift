import AppKit
import ArgumentParser
import Foundation
import Yams
import SwiftUI

extension FileManager {

    func recursivelyListDirectory(
        at url: URL
    ) -> [String] {
        var result: [String] = []
        let dirEnum = enumerator(atPath: url.path)
        while let file = dirEnum?.nextObject() as? String {
            result.append(file)
        }
        return result
    }
}

extension Color {
    
    static var primaryColor: Color {
        Color(red: 88/255, green: 86/255, blue: 215/255)
    }
    
    static var customGray: Color {
        Color(red: 100/255, green: 100/255, blue: 100/255)
    }
}

extension NSImage {
    
    @MainActor
    func saveAsJPEG(to url: URL, compressionQuality: CGFloat = 1.0) throws {
        guard let tiffRepresentation = tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffRepresentation),
              let imageData = imageRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            throw NSError(domain: "com.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create JPEG representation"])
        }
        
        try imageData.write(to: url)
    }
}

struct CoverView: View {
    
    let title: String
    let description: String
    let logoUrl: URL

    var body: some View {
        VStack(
            alignment: .leading
        ) {
            Text("swiftonserver.com")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primaryColor)
            Spacer()
                .frame(height: 0)
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
            Spacer()
                .frame(height: 16)
            Text(description)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.customGray)
            
            Spacer()
                .frame(height: 32)
            
            Image(nsImage: .init(contentsOf: logoUrl)!)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.tint)
                .frame(width: 222, height: 46)
        }
        .padding(32)
        .frame(width: 640, height: 360)
        .background(Color.white)
    }
}

@main
struct Entrypoint: AsyncParsableCommand {

    @Argument(help: "The input directory.")
    var input: String = "../contents/blog/posts"
    
    @MainActor
    mutating func run() async throws {
        
        let currentDir = FileManager.default.currentDirectoryPath
        let workUrl = URL(fileURLWithPath: currentDir)
            .appendingPathComponent(input)
        
        let list = FileManager.default.recursivelyListDirectory(at: workUrl)
            .filter {
                !$0.contains("{{") && !$0.contains("}}")
            }
            .filter {
                $0.hasSuffix("/index.md") || $0.hasSuffix("/index.markdown")
            }
        
        let decoder = YAMLDecoder()
        
        struct Meta: Codable {
            let title: String
            let description: String
        }
        
        let logoUrl = Bundle.module.url(
            forResource: "sots-horizontal",
            withExtension: "jpg"
        )!

        for item in list {
            let url = workUrl.appendingPathComponent(item)
            let postDir  = "/" + url.pathComponents.dropLast(1).dropFirst().joined(separator: "/")
            let postUrl = URL(fileURLWithPath: postDir)
            let assetsUrl = postUrl.appendingPathComponent("assets")
            let coverUrl = assetsUrl.appendingPathComponent("cover.jpg")
            
            guard
                !FileManager.default.fileExists(
                    atPath: coverUrl.path()
                )
            else {
                continue
            }

            let yml = try String(contentsOf: url)
                .split(separator: "---")
                .first?
                .map(String.init)
                .joined()
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard let yml else {
                continue
            }
            
            let meta = try decoder.decode(Meta.self, from: yml)

            try? FileManager.default.createDirectory(
                at: assetsUrl,
                withIntermediateDirectories: false
            )

            let view = CoverView(
                title: meta.title,
                description: meta.description,
                logoUrl: logoUrl
            )
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            let image = renderer.nsImage

            try image?.saveAsJPEG(to: coverUrl, compressionQuality: 0.8)
        }
    }
}
