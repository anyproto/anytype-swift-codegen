.DEFAULT_GOAL := release
RELEASE_BIN_FOLDER := $(shell xcrun swift build -c release --arch x86_64 --show-bin-path)

clean-release: clean artifacts-clean release

release: build-release build-dependency-swift-format
	echo "Gathering tools in ./release"
	@mkdir -p ./release
	@cp $(RELEASE_BIN_FOLDER)/anytype-swift-codegen ./release/anytype-swift-codegen
	@cp $(RELEASE_BIN_FOLDER)/swift-format ./release
	@open ./release

test:
	xcrun swift test

build:
	xcrun swift build

build-release:
	xcrun swift build -c release --arch x86_64

build-dependency-swift-format:
	echo "Start build dependent tool swift-format"
	xcrun swift build --product swift-format -c release --arch x86_64

clean:
	xcrun swift package clean

artifacts-clean:
	@rm -rf .build
	@rm -f ./release/*