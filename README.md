# jobdeck-job-worker

## Licenses

Project code is MIT licensed; see `LICENSE`. Third-party Go documents are tracked
under `third_party/licenses/linux-amd64/`. Run `make licenses` (also part of
`make build`) with the pinned mise tools to regenerate them and the proxy's
project-license copy; commit the results. CI's `make check-clean` detects drift.

The worker image includes `/LICENSE` and `/third_party/`. The proxy includes the
project license for its custom scripts/configuration at
`/usr/share/doc/jobdeck-forward-proxy/LICENSE`, preserving inherited upstream
license documents. That project license does not relicense Squid or its base OS.
