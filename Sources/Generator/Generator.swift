import Foundation
import Zip
import WinMD

@main
struct Generator {
    static func main() async throws {
//        let decls = ["one", "two"]
//        let structure = CppStruct(name: "DeploymentProgress") {
//            CFunctionDecl(
//                name: "write",
//                returnType: "int"
//            )
//            
//            CFunctionDecl(
//                name: "read",
//                parameters: ["count"]
//            )
//            
//            for decl in decls {
//                CFunctionDecl(name: decl)
//            }
//        }

//        var format = BasicFormat(stream: .standardOutput())
//        try structure.write(with: &format)
//        try format.flush()
        
        var metadataFiles = try await getMetadataPackage(
            packageID: "Microsoft.Windows.SDK.Contracts",
            packageVersion: "10.0.28000.2705"
        )
        metadataFiles.append(
            contentsOf: try await getMetadataPackage(
                packageID: "Microsoft.Windows.SDK.Win32Metadata",
                packageVersion: "71.0.26-preview"
            )
        )
        metadataFiles.append(
            contentsOf: try await getMetadataPackage(
                packageID: "Microsoft.Windows.WDK.Win32Metadata",
                packageVersion: "0.13.25-experimental"
            )
        )
        metadataFiles.append(
            contentsOf: try await getMetadataPackage(
                packageID: "Microsoft.WindowsAppSDK",
                packageVersion: "2.5.1"
            )
        )
        let database = try MetadataDB(files: metadataFiles)
        
        // Enum
        try write(
            type: database.findTypeDef(
                namespace: "Windows.System.Diagnostics.DevicePortal",
                name: "DevicePortalConnectionClosedReason"
            ),
            metadata: database
        )
        
        // Enum (OptionSet)
        try write(
            type: database.findTypeDef(
                namespace: "Windows.Media.Protection",
                name: "RevocationAndRenewalReasons"
            ),
            metadata: database
        )
        
        // Struct
        try write(
            type: database.findTypeDef(
                namespace: "Windows.Management.Deployment",
                name: "DeploymentProgress"
            ),
            metadata: database
        )
        
        // Class with methods
        try write(
            type: database.findTypeDef(
                namespace: "Windows.Storage",
                name: "StorageFile"
            ),
            metadata: database
        )
    }
    
    static let cacheDirectoryName = ".winmd-cache"
    
    static func getMetadataPackage(
        packageID: String,
        packageVersion: String
    ) async throws -> [MetadataFile] {
        let cachePath = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath
        ).appending(
            components: cacheDirectoryName, packageID, packageVersion,
            directoryHint: .isDirectory
        )
        
        try FileManager.default.createDirectory(
            at: cachePath,
            withIntermediateDirectories: true
        )
        let successPath = cachePath.appending(
            component: ".success",
            directoryHint: .notDirectory
        )
        
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
            
            return metadataFiles
        } else {
            let metadataFiles = try await fetchMetadataPackage(
                cachePath,
                packageID,
                packageVersion
            )
            FileManager.default.createFile(atPath: successPath.path(), contents: nil)
            return metadataFiles
        }
    }
    
    static func fetchMetadataPackage(
        _ cachePath: URL,
        _ packageID: String,
        _ packageVersion: String
    ) async throws -> [MetadataFile] {
        print("Locating package: \(packageID)")
        let packageResourceURL = try await getPackageDownloadURL(
            packageID: packageID,
            packageVersion: packageVersion
        )

        print("Downloading \(packageID) \(packageVersion)")
        let zipData = try await download(url: packageResourceURL)
        
        print("Extracting nupkg")
        let zipEntries = try parseZip(from: zipData.span)
        
        var metadataFiles = [MetadataFile]()
        for entry in zipEntries {
            // Some WinMD files have uppercase letters in the file extension,
            // like `Windows.WinMD` in `Microsoft.Windows.SDK.Contracts`
            guard entry.fileName.lowercased().hasSuffix(".winmd") else {
                continue
            }
            
            let filename = URL(filePath: entry.fileName).lastPathComponent
            let destination = cachePath.appending(component: filename)
            
            let data = try entry.extract(from: zipData.span)
            try data.write(to: destination)
            
            metadataFiles.append(try MetadataFile(parsing: data))
        }
        
        return metadataFiles
    }
}
