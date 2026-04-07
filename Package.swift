// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "windows-kit",
    products: [
        .plugin(name: "windows-kit", targets: ["Plugin"]),
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-binary-parsing", "0.0.1"..."0.0.2"),
        .package(url: "https://github.com/apple/swift-system", from: "1.6.4"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.0")
    ],

    targets: [
        .executableTarget(
            name: "Generator",
            dependencies: [
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "SWCompression", package: "SWCompression")
            ],
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes"),
            ]
        ),
        .plugin(
            name: "Plugin",
            capability: .command(
                intent: .custom(verb: "Generate", description: ""),
                permissions: [.writeToPackageDirectory(reason: "This command generates bindings to Windows APIs")]
            ),
            dependencies: ["Generator"]
        ),
    ]
)
