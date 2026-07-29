#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# EN: Source helpers without running dependency installation.
# KO: 의존성 설치를 실행하지 않고 헬퍼만 불러옵니다.
source "$REPO_ROOT/ci_post_clone.sh"

sleep() {
  :
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

attempts=0
fail_once() {
  attempts=$((attempts + 1))
  [ "$attempts" -ge 2 ]
}

run_with_retry "fail-once fixture" fail_once >/dev/null
[ "$attempts" -eq 2 ] ||
  fail "fail-once command must run exactly twice"

attempts=0
always_fail() {
  attempts=$((attempts + 1))
  return 7
}

set +e
run_with_retry "always-fail fixture" always_fail >/dev/null
status=$?
set -e

[ "$attempts" -eq 2 ] ||
  fail "always-fail command must run exactly twice"
[ "$status" -eq 7 ] ||
  fail "second failure status must propagate"

printf 'ci_post_clone retry tests passed\n'
