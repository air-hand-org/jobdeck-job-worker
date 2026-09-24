.PHONY: go-build
go-build:
	@go generate ./... && go mod tidy && go build ./...

.PHONY: go-fmt
go-fmt:
	@golangci-lint fmt ./...

.PHONY: go-lint
go-lint:
	@golangci-lint fmt ./... --diff && golangci-lint run ./...

.PHONY: go-test
go-test:
	@go test -cover ./...
