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
        print("Locating package: \(packageID)")
        let packageResourceURL = try await getPackageDownloadURL(packageID: packageID, packageVersion: packageVersion)

        print("Downloading \(packageID) \(packageVersion)")
        let contents = try await download(url: packageResourceURL)

        let cacheURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(cacheDirectoryName)
        try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)

        // try contents.write(to: cacheURL.appendingPathComponent("contracts.zip"))
        
        print("Extracting nupkg")
        // Test zip parser
        let zipEntries = try parseZip(byteSpan: contents.span)
        
        guard let cdEntry = zipEntries.first(where: { $0.fileName.hasPrefix("ref/netstandard2.0") }) else {
            print("Missing")
            return
        }
        
        guard cdEntry.compressionMethod == .deflate else {
            print("Not deflate")
            return
        }
        
        let zipEntry = try ZipEntry(span: contents.span, centralDirectoryEntry: cdEntry)
        let filename = URL(filePath: zipEntry.fileName).lastPathComponent
        
        let mdPath = cacheURL.appending(component: filename)
        
        let data = try zipEntry.extract()
        try data.write(to: mdPath)
        print("Extracted")

//        for entry in zip {
//            let path = entry.info.name
//            
//            guard path.hasPrefix("ref/netstandard2.0"),
//                  path.hasSuffix(".winmd"),
//                  entry.info.type == .regular
//            else {
//                continue
//            }
//
//            let filename = URL(fileURLWithPath: path).lastPathComponent
//            let destinationURL = cacheURL.appendingPathComponent(filename)
//
//            if let fileData = entry.data {
//                try fileData.write(to: destinationURL)
//            }
//        }
//
//        print("Parsing first metadata file")
//        if let firstData = zip.first?.data {
//            if let magicNumber = String(data: firstData.prefix(3), encoding: .ascii) {
//                print(magicNumber)
//            }
//            let metadata = try MetadataDB(data: firstData)
//        }

    }
}
