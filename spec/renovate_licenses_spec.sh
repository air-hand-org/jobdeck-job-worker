Describe 'Renovate license change validation'
  script="$SHELLSPEC_PROJECT_ROOT/.github/scripts/validate-renovate-licenses.sh"
  setup() {
    fixture_root=$(mktemp -d)
    mkdir "$fixture_root/work"
    cd "$fixture_root/work" || return
    git init -q
    git config user.name Test
    git config user.email test@example.invalid
    mkdir -p third_party/licenses/linux-amd64/example
    printf original > third_party/licenses/linux-amd64/example/LICENSE
    printf original > LICENSE
    printf 'module example\n' > go.mod
    git add .
    git commit -qm initial
    EXPECTED_HEAD=$(git rev-parse HEAD)
    ELIGIBLE=true
    export EXPECTED_HEAD ELIGIBLE
  }
  cleanup() { cd "$SHELLSPEC_PROJECT_ROOT"; rm -rf "$fixture_root"; }
  BeforeEach setup
  AfterEach cleanup
  validate() { bash "$script"; }
  change_license() { printf updated > third_party/licenses/linux-amd64/example/LICENSE; }
  It 'accepts a clean tree'
    When call validate
    The status should be success
  End
  allowed() { change_license; validate; }
  It 'accepts only generated licenses'
    When call allowed
    The status should be success
  End
  Context 'outside changes mixed with an allowed license'
    Parameters
      LICENSE
      containers/forward-proxy/LICENSE
      go.mod
      go.sum
      internal/app/gen_worker_moq_test.go
      internal/generated.go
      README.md
      third_party/licenses/linux-arm64/example/LICENSE
      third_party/licenses/linux-amd64-other/LICENSE
    End
    reject_outside() {
      change_license
      mkdir -p "$(dirname "$1")"
      printf unexpected > "$1"
      validate
    }
    It 'rejects each outside path before staging'
      When call reject_outside "$1"
      The status should be failure
      The stderr should include 'Outside generated license scope'
    End
  End
  Context 'change enumeration'
    Parameters
      staged
      deleted
      rename
      untracked
      symlink
    End
    outside_variant() {
      change_license
      case "$1" in
        staged) printf unexpected > go.mod; git add go.mod ;;
        deleted) rm LICENSE ;;
        rename) mv LICENSE third_party/licenses/linux-amd64/moved ;;
        untracked) printf unexpected > new-source.go ;;
        symlink) rm -rf third_party/licenses/linux-amd64; ln -s "$fixture_root" third_party/licenses/linux-amd64 ;;
      esac
      validate
    }
    It 'rejects tracked, staged, untracked, rename and symlink escapes'
      When call outside_variant "$1"
      The status should be failure
      The stderr should not be blank
    End
  End
  Context 'input guards'
    Parameters
      missing-eligibility
      malformed-eligibility
      missing-head
      malformed-head
      wrong-head
    End
    invalid_input() {
      change_license
      case "$1" in
        missing-eligibility) unset ELIGIBLE ;;
        malformed-eligibility) ELIGIBLE=yes ;;
        missing-head) unset EXPECTED_HEAD ;;
        malformed-head) EXPECTED_HEAD=bad ;;
        wrong-head) EXPECTED_HEAD=0000000000000000000000000000000000000000 ;;
      esac
      validate
    }
    It 'fails closed on missing or invalid eligible inputs'
      When call invalid_input "$1"
      The status should be failure
      The stderr should not be blank
    End
  End
  ineligible() {
    printf outside > go.mod
    ELIGIBLE=false EXPECTED_HEAD= bash "$script" || return
    test -z "$(git diff --cached --name-only)"
  }
  It 'leaves unrelated PRs untouched without requiring PR inputs'
    When call ineligible
    The status should be success
  End
End
