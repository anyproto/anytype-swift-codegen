// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnytypeSwiftCodegen",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "anytype-swift-codegen", targets: ["anytype-swift-codegen"]),
        .library(name: "AnytypeSwiftCodegen", targets: ["AnytypeSwiftCodegen"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax", exact: "0.50700.0"),
        .package(url: "https://github.com/Carthage/Commandant", from: "0.17.0"),
        .package(url: "https://github.com/thoughtbot/Curry", from: "4.0.2"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.1.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.0.0"),
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.14.2"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .executableTarget(
            name: "anytype-swift-codegen",
            dependencies: ["AnytypeSwiftCodegen", "Commandant", "Curry", "Files"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath", "-Xlinker",
                    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx"
                ])
            ]),
        .target(
            name: "AnytypeSwiftCodegen",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "StencilSwiftKit", package: "StencilSwiftKit")
            ]),
        .testTarget(
            name: "AnytypeSwiftCodegenTests",
            dependencies: [
                "AnytypeSwiftCodegen",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]),
    ]
)
