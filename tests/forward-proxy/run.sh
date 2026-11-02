#!/bin/sh
set -eu

compose_file="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/compose.yaml"
project_name="jobdeck_forward_proxy_test_$$"

: "${FORWARD_PROXY_IMAGE:?FORWARD_PROXY_IMAGE must be set}"

cleanup() {
    result=$?
    if [ "$result" -ne 0 ]; then
        docker compose --project-name "$project_name" --file "$compose_file" logs >&2
    fi
    docker compose --project-name "$project_name" --file "$compose_file" down --volumes --remove-orphans
}
trap cleanup EXIT INT TERM

# Validate explicit false and reject malformed opt-ins through the real entrypoint.
docker compose --project-name "$project_name" --file "$compose_file" run --rm --no-deps \
    -e SQUID_ALLOW_PRIVATE_DEMO=false forward-proxy -k parse
if docker compose --project-name "$project_name" --file "$compose_file" run --rm --no-deps \
    -e SQUID_ALLOW_PRIVATE_DEMO=invalid forward-proxy -k parse; then
    echo "invalid private-demo opt-in was accepted" >&2
    exit 1
fi

docker compose --project-name "$project_name" --file "$compose_file" up --detach

proxy_url() {
    port="$(docker compose --project-name "$project_name" --file "$compose_file" port "$1" 3128 | sed 's/.*://')"
    printf 'http://127.0.0.1:%s' "$port"
}

strict_url="$(proxy_url forward-proxy)"
local_url="$(proxy_url local-forward-proxy)"
for proxy in "$strict_url" "$local_url"; do
    attempt=1
    while ! curl --max-time 2 --fail --silent --show-error --noproxy "" --proxy "$proxy" http://public.demo.test:8080/ > /dev/null; do
        if [ "$attempt" -ge 30 ]; then
            exit 1
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
done

expect_status() {
    expected=$1
    proxy=$2
    url=$3
    status="$(curl --max-time 5 --silent --show-error --output /dev/null --write-out '%{http_code}' --noproxy "" --proxy "$proxy" "$url")"
    printf '%s: expected %s, got %s\n' "$url" "$expected" "$status"
    test "$status" = "$expected"
}

expect_connect_status() {
    expected=$1
    proxy=$2
    destination=$3
    # curl exits nonzero on a rejected CONNECT; assert the proxy response itself.
    status="$(curl --max-time 5 --silent --output /dev/null --write-out '%{http_connect}' --noproxy "" --proxy "$proxy" --proxytunnel "http://$destination/" || true)"
    printf 'CONNECT %s: expected %s, got %s\n' "$destination" "$expected" "$status"
    test "$status" = "$expected"
}

# The configured domain and port must not bypass private-address denial.
expect_status 403 "$strict_url" http://private.demo.test:8080/
expect_connect_status 403 "$strict_url" private.demo.test:8080
# Local Aspire may explicitly opt in, but only for the configured private demo.
expect_status 200 "$local_url" http://private.demo.test:8080/
expect_connect_status 200 "$local_url" private.demo.test:8080
for proxy in "$strict_url" "$local_url"; do
    expect_status 200 "$proxy" http://public.demo.test:8080/
    expect_connect_status 200 "$proxy" public.demo.test:8080
    expect_status 403 "$proxy" http://public.demo.test:443/
    expect_status 403 "$proxy" http://private.demo.test:8081/
    expect_status 403 "$proxy" http://denied.test:8080/
    for host in loopback linklocal unique-local linklocal-v6 loopback-v6; do
        # ULA is private and therefore intentionally allowed only in local mode.
        if [ "$proxy" = "$local_url" ] && [ "$host" = unique-local ]; then
            continue
        fi
        expect_status 403 "$proxy" "http://$host.demo.test:8080/"
        expect_connect_status 403 "$proxy" "$host.demo.test:8080"
    done
    expect_connect_status 403 "$proxy" www.google.com:443
done

echo "forward proxy allow/deny integration test passed"
