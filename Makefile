SHELL := /bin/bash
# Command Line Tools ship Swift Testing outside the default search paths.
CLT_FRAMEWORKS := /Library/Developer/CommandLineTools/Library/Developer/Frameworks
CLT_LIBS := /Library/Developer/CommandLineTools/Library/Developer/usr/lib
SWIFT_FLAGS := --build-system native
TEST_FLAGS := $(SWIFT_FLAGS) \
	-Xswiftc -F$(CLT_FRAMEWORKS) \
	-Xlinker -F$(CLT_FRAMEWORKS) \
	-Xlinker -rpath -Xlinker $(CLT_FRAMEWORKS) \
	-Xlinker -rpath -Xlinker $(CLT_LIBS)

.PHONY: test lint format check app install package clean preview

test:
	swift test $(TEST_FLAGS) 2>&1 | grep -v "build-system native' has been deprecated"; exit $${PIPESTATUS[0]}

lint:
	swift format lint --strict --recursive Package.swift Sources Tests

format:
	swift format --in-place --recursive Package.swift Sources Tests

check: lint test

app:
	scripts/build-app.sh

install: app
	scripts/install.sh

package:
	scripts/package.sh

clean:
	rm -rf .build build

preview:
	swift run --build-system native PulsePreview build/preview.png 2>&1 | grep -v "has been deprecated"
