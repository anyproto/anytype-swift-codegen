.DEFAULT_GOAL := build

VERSION = $(shell git describe --always --tags --dirty)
VERSION_FILE = $(shell find ./ -name 'Version.swift')
# XCODE = /Applications/Xcode_12.2.app

clean:
	swift package clean

force-clean:
	rm -rf .build

build: version
	@#env DEVELOPER_DIR=$(XCODE) xcrun swift build
	xcrun swift build

build-release:
	@#env DEVELOPER_DIR=$(XCODE) xcrun swift build -c release --disable-sandbox
	xcrun swift build -c release

test:
	@#env DEVELOPER_DIR=$(XCODE) xcrun swift test
	xcrun swift test

release: version build-release reset-version

version:
	@# avoid tracking changes for file:
	@git update-index --assume-unchanged $(VERSION_FILE)
	@echo VERSION: $(VERSION)
	@echo "public let ToolVersion = \"$(VERSION)\"" > $(VERSION_FILE)

reset-version:
	@# reset version file
	@git checkout $(VERSION_FILE)