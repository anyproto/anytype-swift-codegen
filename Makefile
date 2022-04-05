.DEFAULT_GOAL := build

clean:
	xcrun swift package clean

artifacts-clean:
	@rm -rf .build
	@rm -f ./release/*

clean-hard: clean artifacts-clean

build:
	xcrun swift build

build-release:
	xcrun swift build -c release

build-dependency-swift-format:
	echo "Start build dependent tool swift-format"
	xcrun swift build --product swift-format -c release

test:
	xcrun swift test

release: build-release build-dependency-swift-format
	echo "Gathering tools in ./release"
	@cp ./.build/release/anytype-swift-codegen ./release
	@cp ./.build/release/swift-format ./release

clean-release: clean artifacts-clean release