.DEFAULT_GOAL := release

clean-release: clean artifacts-clean release

release: build-release build-dependency-swift-format
	echo "Gathering tools in ./release"
	@cp ./.build/apple/Products/Release/anytype-swift-codegen ./release
	@cp ./.build/apple/Products/Release/swift-format ./release
	@open ./release

test:
	xcrun swift test

build:
	xcrun swift build

build-release:
	xcrun swift build -c release --arch x86_64 --arch arm64

build-dependency-swift-format:
	echo "Start build dependent tool swift-format"
	xcrun swift build --product swift-format -c release --arch x86_64 --arch arm64 

clean:
	xcrun swift package clean

artifacts-clean:
	@rm -rf .build
	@rm -f ./release/*