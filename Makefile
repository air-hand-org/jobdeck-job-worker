all: setup build

include ./mkfiles/*.mk

.PHONY: setup
setup:
	@aqua i && mise i

.PHONY: build
build: go-build

.PHONY: fmt
fmt: go-fmt

.PHONY: lint
lint: go-lint

.PHONY: check-clean
check-clean:
	@git status --short
	@test -z "$$(git status --porcelain)"

.PHONY: test
test: go-test
