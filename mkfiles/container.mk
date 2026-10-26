CONTAINER_MK := $(lastword $(MAKEFILE_LIST))
CONTAINER_MK_DIR := $(dir $(abspath $(CONTAINER_MK)))

.PHONY: container-build
container-build: container-build-go container-build-other

.PHONY: container-build-go
container-build-go:
	@cd $(CONTAINER_MK_DIR)../ \
	&& docker build \
		. \
	;

.PHONY: container-build-other
container-build-other:
	@cd $(CONTAINER_MK_DIR)../containers/forward-proxy \
	&& docker build . \
	;

.PHONY: forward-proxy-integration-test
forward-proxy-integration-test:
	@cd $(CONTAINER_MK_DIR)../ \
	&& FORWARD_PROXY_IMAGE=jobdeck-forward-proxy:test sh ./tests/forward-proxy/run.sh
