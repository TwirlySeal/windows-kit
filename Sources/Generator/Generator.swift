import Foundation
import Zip

@main
struct Generator {
    static func main() async {
        do {
            try await run()
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static let packageID = "Microsoft.Windows.SDK.Contracts"
    static let packageVersion = "10.0.28000.1721"
    static let cacheDirectoryName = ".winmd-cache"
    
    static func run() async throws {
        let cachePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(
                components: cacheDirectoryName, packageID, packageVersion,
                directoryHint: .isDirectory
            )
        
        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
        let successPath = cachePath.appending(component: ".success", directoryHint: .notDirectory)
        
        if FileManager.default.fileExists(atPath: successPath.path()) {
            let metadataFileURLs = try FileManager.default.contentsOfDirectory(
                at: cachePath,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            for metadataFileURL in metadataFileURLs {
                let data = try Data(contentsOf: metadataFileURL, options: .mappedIfSafe)
                
                // Test WinMD parser
                let metadata = try MetadataDB(data: data)
            }
        } else {
            try await runRemote(cachePath: cachePath)
            FileManager.default.createFile(atPath: successPath.path(), contents: nil)
        }
    }
    
    static func runRemote(cachePath: URL) async throws {
        print("Locating package: \(packageID)")
        let packageResourceURL = try await getPackageDownloadURL(packageID: packageID, packageVersion: packageVersion)

        print("Downloading \(packageID) \(packageVersion)")
        let contents = try await download(url: packageResourceURL)
        
        print("Extracting nupkg")
        let cdEntries = try parseZip(byteSpan: contents.span)
        
        for entry in cdEntries {
            guard entry.fileName.hasPrefix("ref/netstandard2.0"),
                  entry.fileName.hasSuffix(".winmd") else {
                continue
            }
            
            let zipEntry = try ZipEntry(span: contents.span, centralDirectoryEntry: entry)
            
            let filename = URL(filePath: zipEntry.fileName).lastPathComponent
            let destination = cachePath.appending(component: filename)
            
            let data = try zipEntry.extract()
            try data.write(to: destination)
            
            // Test WinMD parser
            let metadata = try MetadataDB(data: data)
        }
    }
}
