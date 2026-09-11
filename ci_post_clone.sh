#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_PLIST_PATH="$ROOT_DIR/ios/Runner/GoogleService-Info.plist"

# EN: Xcode Cloud defaults to staging; production builds must opt in with an
#     explicit APP_ENV value in the workflow configuration.
# KO: Xcode Cloud는 staging을 기본으로 사용하며, 운영 빌드는 워크플로우에서
#     APP_ENV를 명시적으로 지정해야 합니다.
APP_ENV="${APP_ENV:-staging}"
case "$APP_ENV" in
  development|staging|production)
    ;;
  *)
    echo "Unsupported APP_ENV: $APP_ENV" >&2
    exit 1
    ;;
esac
export APP_ENV

log() {
  printf '[ci_post_clone] %s\n' "$1"
}

run_with_retry() {
  local description="$1"
  shift

  log "Running $description"
  if "$@"; then
    return 0
  fi

  log "$description failed; retrying once in 5 seconds"
  sleep 5
  "$@"
}

decode_base64_to_file() {
  local encoded="$1"
  local output="$2"
  local normalized=""

  if printf '%s' "$encoded" | base64 --decode > "$output" 2>/dev/null; then
    return 0
  fi
  if printf '%s' "$encoded" | base64 -D > "$output" 2>/dev/null; then
    return 0
  fi
  if printf '%s' "$encoded" | base64 -d > "$output" 2>/dev/null; then
    return 0
  fi

  # Retry after removing whitespace/newlines (common in copied base64 values).
  normalized="$(printf '%s' "$encoded" | tr -d '\r\n\t ')"
  if [ -n "$normalized" ]; then
    if printf '%s' "$normalized" | base64 --decode > "$output" 2>/dev/null; then
      return 0
    fi
    if printf '%s' "$normalized" | base64 -D > "$output" 2>/dev/null; then
      return 0
    fi
    if printf '%s' "$normalized" | base64 -d > "$output" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

create_ios_google_service_info_plist() {
  if [ -f "$IOS_PLIST_PATH" ]; then
    echo "GoogleService-Info.plist already exists; skip generation."
    return 0
  fi

  mkdir -p "$(dirname "$IOS_PLIST_PATH")"

  # Preferred: raw plist secret (full file content).
  if [ -n "${GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
    printf '%s' "$GOOGLE_SERVICE_INFO_PLIST" > "$IOS_PLIST_PATH"
    echo "Generated GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST."
    return 0
  fi

  # Alternative: base64-encoded full plist.
  if [ -n "${GOOGLE_SERVICE_INFO_PLIST_B64:-}" ]; then
    if decode_base64_to_file "$GOOGLE_SERVICE_INFO_PLIST_B64" "$IOS_PLIST_PATH"; then
      echo "Generated GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_B64."
      return 0
    fi
    # Graceful fallback when raw plist content was accidentally saved
    # into the *_B64 secret.
    if printf '%s' "$GOOGLE_SERVICE_INFO_PLIST_B64" | grep -qi '<plist'; then
      printf '%s' "$GOOGLE_SERVICE_INFO_PLIST_B64" > "$IOS_PLIST_PATH"
      echo "GOOGLE_SERVICE_INFO_PLIST_B64 looked like raw plist; used as-is."
      return 0
    fi
    echo "Failed to decode GOOGLE_SERVICE_INFO_PLIST_B64."
    echo "Hint: regenerate with: base64 -i ios/Runner/GoogleService-Info.plist | tr -d '\\n'"
    exit 1
  fi

  # Fallback: compose from discrete Firebase iOS env vars.
  if [ -n "${FIREBASE_IOS_API_KEY:-}" ] &&
    [ -n "${FIREBASE_IOS_APP_ID:-}" ] &&
    [ -n "${FIREBASE_IOS_MESSAGING_SENDER_ID:-}" ] &&
    [ -n "${FIREBASE_IOS_PROJECT_ID:-}" ] &&
    [ -n "${FIREBASE_IOS_BUNDLE_ID:-}" ]; then
    cat > "$IOS_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>API_KEY</key>
  <string>${FIREBASE_IOS_API_KEY}</string>
  <key>GCM_SENDER_ID</key>
  <string>${FIREBASE_IOS_MESSAGING_SENDER_ID}</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>${FIREBASE_IOS_BUNDLE_ID}</string>
  <key>PROJECT_ID</key>
  <string>${FIREBASE_IOS_PROJECT_ID}</string>
  <key>STORAGE_BUCKET</key>
  <string>${FIREBASE_IOS_STORAGE_BUCKET:-${FIREBASE_IOS_PROJECT_ID}.appspot.com}</string>
  <key>IS_ADS_ENABLED</key>
  <false/>
  <key>IS_ANALYTICS_ENABLED</key>
  <true/>
  <key>IS_APPINVITE_ENABLED</key>
  <true/>
  <key>IS_GCM_ENABLED</key>
  <true/>
  <key>IS_SIGNIN_ENABLED</key>
  <true/>
  <key>GOOGLE_APP_ID</key>
  <string>${FIREBASE_IOS_APP_ID}</string>
</dict>
</plist>
EOF
    echo "Generated GoogleService-Info.plist from FIREBASE_IOS_* variables."
    return 0
  fi

  echo "Missing GoogleService-Info.plist secret."
  echo "Set one of these Xcode Cloud configurations:"
  echo "  - GOOGLE_SERVICE_INFO_PLIST_B64 (recommended)"
  echo "  - GOOGLE_SERVICE_INFO_PLIST (raw plist content)"
  echo "  - FIREBASE_IOS_API_KEY / APP_ID / MESSAGING_SENDER_ID / PROJECT_ID / BUNDLE_ID"
  exit 1
}

main() {
  create_ios_google_service_info_plist
  run_with_retry "flutter pub get" flutter pub get
  run_with_retry \
    "flutter build ios --release --config-only ($APP_ENV)" \
    flutter build ios --release --config-only --dart-define="APP_ENV=$APP_ENV"
  (
    cd "$ROOT_DIR/ios"
    run_with_retry "pod install --repo-update" pod install --repo-update
  )
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
