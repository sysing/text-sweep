.PHONY: build test test-filter clean build-app open

XCDIR = /Applications/Xcode.app/Contents/Developer

build:
	DEVELOPER_DIR=$(XCDIR) swift build

test:
	DEVELOPER_DIR=$(XCDIR) swift test --parallel

test-filter:
	DEVELOPER_DIR=$(XCDIR) swift test --filter "$(F)"

clean:
	swift package clean
	rm -rf .build

build-app:
	xcodebuild -project App/TextSweep.xcodeproj -scheme TextSweep -configuration Release build

open:
	open App/TextSweep.xcodeproj
