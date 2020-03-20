export GO111MODULE=on

TIMESTAMP := $(shell date '+%m%d%H%M%Y.%S')
RELEASE_TAG   ?= $(TIMESTAMP)

# Default Go linker flags.
GO_LDFLAGS ?= -ldflags="-s -w -X main.Version=${RELEASE_TAG}"

# Binary name.
ART := ./bin/art
ARTOSX := ./bin/art-osx
ARTWIN := ./bin/art.exe

.PHONY: all
all: clean vet lint $(ART) $(ARTOSX) $(ARTWIN) test

$(ART):
	GOOS=linux go build -mod=vendor $(GO_LDFLAGS) $(BUILDARGS) -o $@ .

$(ARTOSX):
	GOOS=darwin GOARCH=amd64 go build -mod=vendor $(GO_LDFLAGS) $(BUILDARGS) -o $@ .

$(ARTWIN):
	GOOS=windows GOARCH=386  go build -mod=vendor $(GO_LDFLAGS) $(BUILDARGS) -o $@ .

.PHONY: vendor
vendor:
	go mod tidy
	go mod vendor

.PHONY: test
test:
	go test -mod=vendor -timeout=30s $(TESTARGS) ./...
	@$(MAKE) vet
	@if [ -z "${CODEBUILD_BUILD_ID}" ]; then $(MAKE) lint; fi

.PHONY: vet
vet:
	go vet -mod=vendor $(VETARGS) ./...

.PHONY: lint
lint:
	@echo "golint $(LINTARGS)"
	@for pkg in $(shell go list ./...) ; do \
		golint $(LINTARGS) $$pkg ; \
	done

.PHONY: cover
cover:
	@$(MAKE) test TESTARGS="-coverprofile=coverage.out"
	@go tool cover -html=coverage.out
	@rm -f coverage.out

.PHONY: clean
clean:
	@rm -rf ./bin

.PHONY: package
package: all
	zip -j bin/art.zip $(ART)
	zip -j bin/art-osx.zip $(ARTOSX)
	zip -j bin/art-win.zip $(ARTWIN)
	shasum -a 256 bin/art.zip > bin/art.sha256
	shasum -a 256 bin/art-osx.zip > bin/art-osx.sha256
	shasum -a 256 bin/art-win.zip > bin/art-win.sha256
