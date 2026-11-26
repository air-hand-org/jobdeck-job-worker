.PHONY: go-build
go-build:
	@go generate ./... && go mod tidy && go build ./...

.PHONY: go-fmt
go-fmt:
	@golangci-lint fmt ./...

.PHONY: go-lint
go-lint:
	@golangci-lint fmt ./... --diff && golangci-lint run ./...

# Set to a seed printed by go test to reproduce the test order.
GO_TEST_SHUFFLE ?= on

.PHONY: go-test go-test-race
go-test:
	@go test -shuffle="$(GO_TEST_SHUFFLE)" -cover $(GO_TEST_FLAGS) ./...

go-test-race: GO_TEST_FLAGS := -race
go-test-race: go-test
