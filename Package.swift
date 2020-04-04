// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnytypeSwiftCodegen",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "anytype-swift-codegen", targets: ["anytype-swift-codegen"]),
        .library(name: "AnytypeSwiftCodegen", targets: ["AnytypeSwiftCodegen"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", ._branchItem("swift-5.2-branch")),//.exact("0.50100.0")
//        .package(url: "https://github.com/inamiy/FunOptics", from: "1.0.0"),
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.17.0"),
        .package(url: "https://github.com/thoughtbot/Curry.git", from: "4.0.2"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.1.1"),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-format.git", ._branchItem("swift-5.2-branch"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "anytype-swift-codegen",
            dependencies: ["AnytypeSwiftCodegen", "Commandant", "Curry", "Files"]),
        .target(
            name: "AnytypeSwiftCodegen",
            dependencies: ["SwiftSyntax"]),
        .testTarget(
            name: "AnytypeSwiftCodegenTests",
            dependencies: ["AnytypeSwiftCodegen", "SnapshotTesting"]),
    ]
)
