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
Thank you for your desire to develop Anytype together!

❤️ This project and everyone involved in it is governed by the [Code of Conduct](https://github.com/anyproto/.github/blob/main/docs/CODE_OF_CONDUCT.md).

🧑‍💻 Check out our [contributing guide](https://github.com/anyproto/.github/blob/main/docs/CONTRIBUTING.md) to learn about asking questions, creating issues, or submitting pull requests.

🫢 For security findings, please email [security@anytype.io](mailto:security@anytype.io) and refer to our [security guide](https://github.com/anyproto/.github/blob/main/docs/SECURITY.md) for more information.

🤝 Follow us on [Github](https://github.com/anyproto) and join the [Contributors Community](https://github.com/orgs/anyproto/discussions).

---
Made by Any — a Swiss association 🇨🇭

Licensed under [MIT License](./LICENSE.md).