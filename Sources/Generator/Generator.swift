import Foundation
import Zip
import WinMD

@main
struct Generator {
    static func main() async throws {
        // Test MetadataDB
        let database = try await getDatabase()
        
        for (_, namespaceTypes) in database.types {
            for (name, types) in namespaceTypes {
                for type in types {
                    if try type.category == .class && name == "StorageFile" {
                        try write(type: type)
                        return
                    }
                }
            }
        }
    }
    
    static let packageID = "Microsoft.Windows.SDK.Contracts"
    static let packageVersion = "10.0.28000.1721"
    static let cacheDirectoryName = ".winmd-cache"
    
    static func getDatabase() async throws -> MetadataDB {
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
            let metadataFiles = try metadataFileURLs.map { url in
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                return try MetadataFile(parsing: data)
            }
            
            return try MetadataDB(files: metadataFiles)
        } else {
            let database = try await databaseFromNuGet(cachePath: cachePath)
            FileManager.default.createFile(atPath: successPath.path(), contents: nil)
            return database
        }
    }
    
    static func databaseFromNuGet(cachePath: URL) async throws -> MetadataDB {
        print("Locating package: \(packageID)")
        let packageResourceURL = try await getPackageDownloadURL(packageID: packageID, packageVersion: packageVersion)

        print("Downloading \(packageID) \(packageVersion)")
        let contents = try await download(url: packageResourceURL)
        
        print("Extracting nupkg")
        let cdEntries = try parseZip(from: contents.span)
        
        var metadataFiles = [MetadataFile]()
        metadataFiles.reserveCapacity(cdEntries.count)
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
            
            metadataFiles.append(try MetadataFile(parsing: data))
        }
        
        return try MetadataDB(files: metadataFiles)
    }
}
