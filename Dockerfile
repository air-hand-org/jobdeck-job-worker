# syntax=docker/dockerfile:1

FROM ghcr.io/jdx/mise:2026.10.15-debian AS build
WORKDIR /src
ENV GOPATH=/go \
    GOTOOLCHAIN=local \
    GOWORK=off \
    MISE_NO_ENV=1 \
    MISE_TRUSTED_CONFIG_PATHS=/src

COPY mise.toml ./
RUN mise install && mise reshim

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod,id=jobdeck-go-mod \
    --mount=type=cache,target=/root/.cache/go-build,id=jobdeck-go-build \
    go mod download

COPY cmd ./cmd
COPY internal ./internal
RUN --mount=type=cache,target=/go/pkg/mod,id=jobdeck-go-mod \
    --mount=type=cache,target=/root/.cache/go-build,id=jobdeck-go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/job-worker ./cmd/worker

FROM gcr.io/distroless/base-debian12:nonroot
COPY --from=build /out/job-worker /job-worker
COPY LICENSE /LICENSE
COPY third_party/licenses/linux-amd64 /third_party
USER nonroot:nonroot
ENTRYPOINT ["/job-worker"]
