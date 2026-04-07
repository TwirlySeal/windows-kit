// import SystemPackage
import Foundation
import FoundationNetworking
import SWCompression

func download(url: URL) async throws -> Data {
	let (data, response) = try await URLSession.shared.data(from: url)
	guard let httpResponse = response as? HTTPURLResponse,
		200...299 ~= httpResponse.statusCode
	else {
		throw URLError(.badServerResponse)
	}
	return data
}

struct Resource: Decodable {
	let url: URL
	let type: String
	let comment: String?

	enum CodingKeys: String, CodingKey {
		case url = "@id"
		case type = "@type"
		case comment = "comment"
	}
}

struct ServiceIndex: Decodable {
	let version: String
	let resources: [Resource]
}

enum NuGetError: Error {
	case missingResource
}

let packageID = "Microsoft.Windows.SDK.Contracts"
let packageVersion = "10.0.28000.1721"
let cacheDirectoryName = ".winmd-cache"

func getPackageDownloadURL() async throws -> URL {
	let indexURL = URL(string: "https://api.nuget.org/v3/index.json")!
	let data = try await download(url: indexURL)
	let serviceIndex = try JSONDecoder().decode(ServiceIndex.self, from: data)

	guard let resource = serviceIndex.resources.first(where: { $0.type == "PackageBaseAddress/3.0.0" }) else {
		throw NuGetError.missingResource
	}

	// equivalent to System.String.ToLowerInvariant() from .NET
	let lowerId = packageID.lowercased(with: Locale(identifier: ""))
	let lowerVersion = packageVersion

	return resource.url
		.appending(path: lowerId)
		.appending(path: lowerVersion)
		.appending(path: "\(lowerId).\(lowerVersion).nupkg")
}

print("Locating package: \(packageID)")
let packageResourceURL = try await getPackageDownloadURL()

print("Downloading \(packageID) \(packageVersion)")
let contents = try await download(url: packageResourceURL)

let cacheURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(cacheDirectoryName)
try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)

try contents.write(to: cacheURL.appendingPathComponent("contracts.zip"))

let zip = try ZipContainer.open(container: contents)

for entry in zip {
	let path = entry.info.name
	print(path)

 guard path.hasPrefix("ref/netstandard2.0"),
 	path.hasSuffix(".winmd"),
 	entry.info.type == .regular
 else {
 	continue
 }

 let filename = URL(fileURLWithPath: path).lastPathComponent
 let destinationURL = cacheURL.appendingPathComponent(filename)

 if let fileData = entry.data {
 	try fileData.write(to: destinationURL)
 }
}

print("Parsing first metadata file")
if let firstData = zip.first?.data {
	let metadata = try MetadataDB(data: firstData)
}
