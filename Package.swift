// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "windows-kit",

    platforms: [
        .macOS(.v10_15)
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-binary-parsing", "0.0.1"..<"0.1.0"),
        // .package(url: "https://github.com/apple/swift-system", from: "1.6.4"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.1"),
        // .package(url: "https://github.com/tayloraswift/swift-png", from: "4.5.1"),
        // .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.0"),
    ],

    targets: [
        .executableTarget(
            name: "Generator",
            dependencies: [
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
                // .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .target(name: "Zip")
                // .product(name: "SWCompression", package: "SWCompression")
            ]
        ),
        .target(
            name: "Zip",
            dependencies: [
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
                // .product(name: "LZ77", package: "swift-png"),
            ],
            // swiftSettings: [
            //     .enableExperimentalFeature("Lifetimes"),
            // ]
        ),
        .macro(
            name: "DeflateMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
    ]
)
