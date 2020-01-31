# AnytypeSwiftCodegen

This repository contains code generation cli utility and swift framework which produces convenient intitializers and services from protobuf models.

## How to use.

1. `git clone <repository>`
2. `swift build`
3. `swift run anytype-swift-codegen [parameters]`
4. `swift run anytype-swift-codegen help`

## How to build release.

1. `swift build -c release`
2. `swift build --product swift-format -c release`
3. `mkdir release`
4. `cp ./.build/release/anytype-swift-codegen ./release`
5. `cp ./.build/release/swift-format ./release`

## How to use tool.

1. `./anytype-swift-codegen help`
2. `./anytype-swift-codegen help generate`
3. `./anytype-swift-codegen help [command_name]`
