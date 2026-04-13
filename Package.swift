// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "windows-kit",

    platforms: [
        .macOS(.v26)
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-binary-parsing", "0.0.1"..<"0.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
    ],

    targets: [
        .executableTarget(
            name: "Generator",
            dependencies: [
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .target(name: "Zip")
            ]
        ),
        .target(
            name: "Zip",
            dependencies: [
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes"),
            ]
        ),
    ]
)
