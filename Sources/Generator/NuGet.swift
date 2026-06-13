import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// https://learn.microsoft.com/en-us/nuget/api/overview
// https://learn.microsoft.com/en-us/nuget/api/service-index
// https://learn.microsoft.com/en-us/nuget/api/package-base-address-resource

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

func getPackageDownloadURL(packageID: String, packageVersion: String) async throws -> URL {
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
