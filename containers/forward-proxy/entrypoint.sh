#!/bin/sh
set -eu

: "${SQUID_ALLOWED_DEMO_HOST_AND_PORT:?SQUID_ALLOWED_DEMO_HOST_AND_PORT must be set}"

case "${SQUID_ALLOWED_DEMO_HOST_AND_PORT}" in
    *:*)
        SQUID_ALLOWED_DEMO_HOST=${SQUID_ALLOWED_DEMO_HOST_AND_PORT%:*}
        SQUID_ALLOWED_DEMO_PORT=${SQUID_ALLOWED_DEMO_HOST_AND_PORT##*:}
        ;;
    *)
        echo "SQUID_ALLOWED_DEMO_HOST_AND_PORT must be in host:port format" >&2
        exit 1
        ;;
esac

if [ -z "${SQUID_ALLOWED_DEMO_HOST}" ]; then
    echo "SQUID_ALLOWED_DEMO_HOST_AND_PORT must include a host" >&2
    exit 1
fi

case "${SQUID_ALLOWED_DEMO_PORT}" in
    *[!0-9]* | '')
        echo "SQUID_ALLOWED_DEMO_HOST_AND_PORT must include a numeric port" >&2
        exit 1
        ;;
esac

# Fail closed unless local private-demo access is explicitly enabled.
case "${SQUID_ALLOW_PRIVATE_DEMO:-false}" in
    true)
        SQUID_PRIVATE_DEMO_ACCESS='http_access allow demo demo_port private_demo_dst'
        ;;
    false)
        SQUID_PRIVATE_DEMO_ACCESS='# Private demo access disabled.'
        ;;
    *)
        echo "SQUID_ALLOW_PRIVATE_DEMO must be true or false" >&2
        exit 1
        ;;
esac

export SQUID_ALLOWED_DEMO_HOST SQUID_ALLOWED_DEMO_PORT SQUID_PRIVATE_DEMO_ACCESS

perl -pe '
    s/\$\{SQUID_ALLOWED_DEMO_HOST\}/$ENV{SQUID_ALLOWED_DEMO_HOST}/g;
    s/\$\{SQUID_ALLOWED_DEMO_PORT\}/$ENV{SQUID_ALLOWED_DEMO_PORT}/g;
    s/\$\{SQUID_PRIVATE_DEMO_ACCESS\}/$ENV{SQUID_PRIVATE_DEMO_ACCESS}/g;
' \
    < /etc/squid/squid.conf.template \
    > /tmp/squid.conf

exec /usr/local/bin/entrypoint.sh -f /tmp/squid.conf "$@"
