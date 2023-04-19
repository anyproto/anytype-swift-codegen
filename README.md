# AnytypeSwiftCodegen

This repository contains code generation cli utility and swift framework which produces convenient intitializers and services from protobuf models.

## How to use.

1. `git clone <repository>`
2. `swift build`
3. `swift run anytype-swift-codegen [parameters]`
4. `swift run anytype-swift-codegen --help`

## How to build release.

`make release`

## How to add plugin in your project.

1. Add to your `Package.swift` file:
```
dependencies: [
    .package(url: "git@github.com:anytypeio/anytype-swift-codegen.git", revision: "[VERSION]")
],
targets: [
    .target(
        ...
        plugins: [
            .plugin(name: "ServiceGenPlugin", package: "AnytypeSwiftCodegen")
        ]
    )
]
```

2. Add config file `anytypeGen.yml` to root package folder. Example:
```
source:
  ./protos/service.proto
template:
  ./Templates/service.stencil
output:
  ./Sources/Generated/service.swift
```
