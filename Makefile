all: setup build

include ./mkfiles/*.mk

.PHONY: setup
setup:
	@aqua i && mise i

.PHONY: build
build: go-build licenses

# Match the linux/amd64 image and its only shipped Go executable.
.PHONY: licenses
licenses:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go-licenses check ./cmd/worker --ignore github.com/air-hand-org/jobdeck-job-worker --disallowed_types=forbidden,unknown
	rm -rf third_party/licenses/linux-amd64
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go-licenses save ./cmd/worker --ignore github.com/air-hand-org/jobdeck-job-worker --save_path third_party/licenses/linux-amd64
	cp LICENSE containers/forward-proxy/LICENSE

.PHONY: fmt
fmt: go-fmt

.PHONY: lint
lint: go-lint

.PHONY: check-clean
check-clean:
	@git status --short
	@test -z "$$(git status --porcelain)"

.PHONY: test
test: go-test shell-test

.PHONY: shell-test
shell-test:
	shellspec
