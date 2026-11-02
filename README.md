# jobdeck-job-worker

## Forward proxy

Set `SQUID_ALLOWED_DEMO_HOST_AND_PORT` to the demo's `host:port`. By default,
private, loopback and link-local destinations are denied **before** the demo
allow rule, including when the configured demo name resolves to those addresses.
Only the configured demo host and port are allowed; there is no Google exception.

Local Aspire uses a private demo endpoint. When adopting this image locally, add
`.WithEnvironment("SQUID_ALLOW_PRIVATE_DEMO", "true")` to the **forward-proxy**
resource (both container and local-source modes use the same proxy environment).
This explicit development-only opt-in permits RFC1918/IPv6 ULA addresses only
for the configured demo host and port. Loopback/link-local destinations and other
hosts/ports remain denied. Leave it unset or `false` in production; other values
are rejected at startup. Existing Aspire wiring must add the opt-in before using
the updated image with a private demo. No central AppHost/IaC files are changed here.

Run `make forward-proxy-integration-test` after building the proxy as
`jobdeck-forward-proxy:test`. The Docker Compose fixtures use isolated internal
networks, including benchmark addresses for a simulated public destination;
requests do not contact production or Google.

## Licenses

Project code is MIT licensed; see `LICENSE`. Third-party Go documents are tracked
under `third_party/licenses/linux-amd64/`. Run `make licenses` (also part of
`make build`) with the pinned mise tools to regenerate them and the proxy's
project-license copy; commit the results. CI's `make check-clean` detects drift.

The worker image includes `/LICENSE` and `/third_party/`. The proxy includes the
project license for its custom scripts/configuration at
`/usr/share/doc/jobdeck-forward-proxy/LICENSE`, preserving inherited upstream
license documents. That project license does not relicense Squid or its base OS.
