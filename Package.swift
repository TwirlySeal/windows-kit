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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],

    targets: [
        .executableTarget(
            name: "Generator",
            dependencies: [
                .target(name: "WinMD"),
                .target(name: "Zip"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "WinMD",
            dependencies: [
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
                .product(name: "Algorithms", package: "swift-algorithms"),
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
