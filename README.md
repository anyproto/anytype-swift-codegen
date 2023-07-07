# Anytype — Swift Codegen

Code generation utility to produce intitializers and services from protobuf models.

## Using

1. `git clone <repository>`
2. `swift build`
3. `swift run anytype-swift-codegen --help`
4. `swift run anytype-swift-codegen [parameters]`

## Building release

`make release`

## Adding to your project

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
## Contribution
Thank you for your desire to develop Anytype together. 

Currently, we're not ready to accept PRs, but we will in the nearest future.

Follow us on [Github](https://github.com/anyproto) and join the [Contributors Community](https://github.com/orgs/anyproto/discussions).

---
Made by Any — a Swiss association 🇨🇭

Licensed under [MIT License](./LICENSE.md).