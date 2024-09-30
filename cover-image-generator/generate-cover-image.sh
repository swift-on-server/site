#!/usr/bin/env DYLD_FRAMEWORK_PATH=/System/Library/Frameworks /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift

import AppKit
import SwiftUI


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
    let workDir: String

    var logoUrl: URL {
        .init(fileURLWithPath: workDir + "/sots-horizontal.jpg")
    }

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

struct Entrypoint {

    @MainActor
    static func main() async throws {
        
        let workDir = FileManager.default.currentDirectoryPath
        let title = ProcessInfo.processInfo.environment["TITLE"]!
        let description = ProcessInfo.processInfo.environment["DESC"]!

        let view = CoverView(
            title: title,
            description: description,
            workDir: workDir
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let image = renderer.nsImage
        let fileURL = URL(fileURLWithPath: workDir + "/cover.jpg")
        try image?.saveAsJPEG(to: fileURL, compressionQuality: 0.8)
    }
}

try await Entrypoint.main()
