#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build_android_internal.sh [major|minor|patch|build]

Examples:
  ./scripts/build_android_internal.sh
  ./scripts/build_android_internal.sh build
  ./scripts/build_android_internal.sh patch
EOF
}

level="${1:-build}"
if [[ "$level" != "major" && "$level" != "minor" && "$level" != "patch" && "$level" != "build" ]]; then
  usage
  exit 1
fi

# EN: Internal distributions use staging by default. Allow an explicit
#     override for local release verification, while rejecting typos before
#     Flutter compiles a channel into the binary.
# KO: 내부 배포는 기본적으로 staging을 사용합니다. 로컬 릴리스 검증을 위한
#     명시적 재정의는 허용하되 Flutter 컴파일 전에 오타를 거부합니다.
app_env="${APP_ENV:-staging}"
case "$app_env" in
  development|staging|production)
    ;;
  *)
    echo "Unsupported APP_ENV: $app_env" >&2
    exit 1
    ;;
esac

./scripts/bump_version.sh "$level"

flutter build appbundle --release --dart-define="APP_ENV=${app_env}"

artifact_path="build/app/outputs/bundle/release/app-release.aab"
if [[ -f "$artifact_path" ]]; then
  echo ""
  echo "Built artifact: $artifact_path"
  ls -lh "$artifact_path"
else
  echo "Build finished but artifact not found at $artifact_path"
  exit 1
fi
