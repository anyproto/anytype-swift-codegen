.DEFAULT_GOAL := release
RELEASE_BIN_FOLDER := $(shell xcrun swift build -c release --arch arm64 --arch x86_64 --show-bin-path)

clean-release: clean artifacts-clean release

release: build-release
	echo "Gathering tools in ./release"
	@mkdir -p ./release
	@cp $(RELEASE_BIN_FOLDER)/anytype-swift-codegen ./release/anytype-codegen-binary.artifactbundle/anytype-swift-codegen/anytype-swift-codegen
	@open ./release

test:
	xcrun swift test

build: reset-package-cache
	swift package reset
	xcrun swift build -target anytype-swift-codegen

build-release: reset-package-cache
	xcrun swift build -c release --arch arm64 --arch x86_64

clean:
	xcrun swift package clean

artifacts-clean:
	@rm -rf .build
	@rm -f ./release/*
	
reset-package-cache:
	swift package reset
