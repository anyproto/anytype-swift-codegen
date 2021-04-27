.DEFAULT_GOAL := build

VERSION = $(shell git describe --always --tags --dirty)
VERSION_FILE = $(shell find ./ -name 'Version.swift')
# XCODE = /Applications/Xcode_12.2.app

clean:
	xcrun swift package clean

artifacts-clean:
	@rm -rf .build
	@rm -f ./release/*

build: version
	@#env DEVELOPER_DIR=$(XCODE) xcrun swift build
	xcrun swift build

build-release:
	@#env DEVELOPER_DIR=$(XCODE) xcrun swift build -c release --disable-sandbox
	xcrun swift build -c release

build-dependency-swift-format:
	echo "Start build dependent tool swift-format"
	xcrun swift build --product swift-format -c release

test:
	@#env DEVELOPER_DIR=$(XCODE) xcrun swift test
	xcrun swift test

release: version build-release build-dependency-swift-format reset-version
	echo "Gathering tools in ./release"
	@cp ./.build/release/anytype-swift-codegen ./release
	@cp ./.build/release/swift-format ./release

clean-release: clean artifacts-clean release

version:
	@# avoid tracking changes for file:
	@git update-index --assume-unchanged $(VERSION_FILE)
	@echo VERSION: $(VERSION)
	@echo "public let ToolVersion = \"$(VERSION)\"" > $(VERSION_FILE)

reset-version:
	@# reset version file
	@git checkout $(VERSION_FILE)
