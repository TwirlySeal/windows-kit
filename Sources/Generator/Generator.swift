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

        // Test zip parser
        try parseZip(byteSpan: contents.span)
        
        // Test deflate parser
        let deflateBlock: [UInt8] = [0b0000_0010]
        var bitSpan = try BitSpan(span: deflateBlock.span)
        try parseDeflate(span: &bitSpan)

        // try contents.withParserSpan { try parseZip(span: &$0) }
        // try contents.write(to: cacheURL.appendingPathComponent("contracts.zip"))

        // print("Extracting nupkg")
        // let zip = try ZipContainer.open(container: contents)
        // print("Extracted")

        // for entry in zip {
        //     let path = entry.info.name

        //  guard path.hasPrefix("ref/netstandard2.0"),
        //      path.hasSuffix(".winmd"),
        //      entry.info.type == .regular
        //  else {
        //      continue
        //  }

        //  let filename = URL(fileURLWithPath: path).lastPathComponent
        //  let destinationURL = cacheURL.appendingPathComponent(filename)

        //  if let fileData = entry.data {
        //      try fileData.write(to: destinationURL)
        //  }
        // }

        // print("Parsing first metadata file")
        // if let firstData = zip.first?.data {
        //     if let magicNumber = String(data: firstData.prefix(3), encoding: .ascii) {
        //         print(magicNumber)
        //     }
        //     let metadata = try MetadataDB(data: firstData)
        // }
    }
}
