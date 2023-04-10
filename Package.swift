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
//        .library(name: "AnytypeSwiftCodegen", targets: ["AnytypeSwiftCodegen"]),
        .plugin(name: "ServiceGenPlugin", targets: ["ServiceGenPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.1"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.1"),
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.14.2"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .executableTarget(
            name: "anytype-swift-codegen",
            dependencies: [
                "AnytypeSwiftCodegen",
                "Yams",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "AnytypeSwiftCodegen",
            dependencies: [
                "Stencil",
                "StencilSwiftKit",
            ]),
        .testTarget(
            name: "AnytypeSwiftCodegenTests",
            dependencies: [
                "AnytypeSwiftCodegen"
            ]),
        .plugin(
            name: "ServiceGenPlugin",
            capability: .buildTool(),
            dependencies: [
                "anytype-codegen-binary"
            ]
        ),
        .binaryTarget(
            name: "anytype-codegen-binary",
            path: "release/anytype-codegen-binary.artifactbundle"
        )
    ]
)
