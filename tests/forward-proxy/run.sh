#!/bin/sh
set -eu

compose_file="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/compose.yaml"
project_name="jobdeck_forward_proxy_test_$$"

: "${FORWARD_PROXY_IMAGE:?FORWARD_PROXY_IMAGE must be set}"

cleanup() {
    docker compose --project-name "$project_name" --file "$compose_file" down --volumes --remove-orphans
}
trap cleanup EXIT INT TERM

docker compose --project-name "$project_name" --file "$compose_file" up --detach

proxy_port="$(docker compose --project-name "$project_name" --file "$compose_file" port forward-proxy 3128 | sed 's/.*://')"
proxy_url="http://127.0.0.1:${proxy_port}"

attempt=1
while ! curl --fail --silent --show-error --noproxy "" --proxy "$proxy_url" http://target:8080/ > /dev/null; do
    if [ "$attempt" -ge 30 ]; then
        docker compose --project-name "$project_name" --file "$compose_file" logs >&2
        exit 1
    fi
    attempt=$((attempt + 1))
    sleep 1
done

deny_status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --noproxy "" --proxy "$proxy_url" http://denied:8080/)"
test "$deny_status" = "403"

echo "forward proxy allow/deny integration test passed"
