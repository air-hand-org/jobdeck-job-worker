#!/usr/bin/env bash
set -euo pipefail
case "${ELIGIBLE:?Specify eligibility}" in
  false) exit 0 ;;
  true) ;;
  *) echo 'Invalid eligibility.' >&2; exit 1 ;;
esac
[[ ${EXPECTED_HEAD:?Specify expected head} =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid expected head.' >&2; exit 1; }
[[ $(git rev-parse --show-prefix) == '' && $(git rev-parse HEAD) == "$EXPECTED_HEAD" ]] || { echo 'Unexpected checkout head or directory.' >&2; exit 1; }
# The shared action selects paths, but intentionally leaves other changes alone.
# Worker must reject those changes before that action can mint a write token.
changes=$(mktemp)
trap 'rm -f "$changes"' EXIT
git diff --no-renames --name-only -z HEAD > "$changes"
git ls-files --others --exclude-standard -z >> "$changes"
root=$(pwd -P)
while IFS= read -r -d '' path; do
  case "$path" in
    third_party/licenses/linux-amd64/*)
      [[ $(realpath -m -- "$path") == "$root/third_party/licenses/linux-amd64/"* ]] && continue
      ;;
  esac
  printf 'Outside generated license scope: %q\n' "$path" >&2
  exit 1
done < "$changes"
