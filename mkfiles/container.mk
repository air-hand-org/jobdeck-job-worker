CONTAINER_MK := $(lastword $(MAKEFILE_LIST))
CONTAINER_MK_DIR := $(dir $(abspath $(CONTAINER_MK)))

.PHONY: container-build
container-build: container-build-go container-build-other

.PHONY: container-build-go
container-build-go:
	@cd $(CONTAINER_MK_DIR)../ \
	&& GITHUB_CONTENTS_TOKEN="$$(gh auth token)" docker build \
		--secret id=github_contents_token,env=GITHUB_CONTENTS_TOKEN \
		. \
	;

.PHONY: container-build-other
container-build-other:
	@cd $(CONTAINER_MK_DIR)../containers/forward-proxy \
	&& docker build . \
	;
