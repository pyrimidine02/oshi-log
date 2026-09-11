#!/bin/sh

# Fail this script if any command fails.
set -eu

log() {
  printf '[ci_post_clone] %s\n' "$1"
}

resolve_repo_root() {
  if [ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ] &&
    [ -d "${CI_PRIMARY_REPOSITORY_PATH:-}" ]; then
    printf '%s' "$CI_PRIMARY_REPOSITORY_PATH"
    return 0
  fi

  script_dir="$(cd "$(dirname "$0")" && pwd)"
  script_based_root="$(cd "$script_dir/../.." && pwd)"
  if [ -d "$script_based_root/ios" ]; then
    printf '%s' "$script_based_root"
    return 0
  fi

  if [ -d "/Volumes/workspace/repository/ios" ]; then
    printf '%s' "/Volumes/workspace/repository"
    return 0
  fi

  pwd
}

REPO_ROOT="$(resolve_repo_root)"

# The default execution directory of this script is the ci_scripts directory.
cd "$REPO_ROOT" # change working directory to the root of your cloned repo.
log "Repository root: $REPO_ROOT"

# EN: Xcode Cloud defaults to staging; production builds must opt in with an
#     explicit APP_ENV workflow variable.
# KO: Xcode Cloud는 staging을 기본으로 사용하며, 운영 빌드는 워크플로우 변수에서
#     APP_ENV를 명시적으로 지정해야 합니다.
APP_ENV="${APP_ENV:-staging}"
case "$APP_ENV" in
  development|staging|production)
    ;;
  *)
    log "Unsupported APP_ENV: $APP_ENV"
    exit 1
    ;;
esac
export APP_ENV

IOS_PLIST_PATH="$REPO_ROOT/ios/Runner/GoogleService-Info.plist"

decode_base64_to_file() {
  encoded="$1"
  output="$2"
  normalized=""

  if printf '%s' "$encoded" | base64 --decode > "$output" 2>/dev/null; then
    return 0
  fi
  if printf '%s' "$encoded" | base64 -D > "$output" 2>/dev/null; then
    return 0
  fi
  if printf '%s' "$encoded" | base64 -d > "$output" 2>/dev/null; then
    return 0
  fi

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

  if [ -n "${GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
    printf '%s' "$GOOGLE_SERVICE_INFO_PLIST" > "$IOS_PLIST_PATH"
    echo "Generated GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST."
    return 0
  fi

  if [ -n "${GOOGLE_SERVICE_INFO_PLIST_B64:-}" ]; then
    if decode_base64_to_file "$GOOGLE_SERVICE_INFO_PLIST_B64" "$IOS_PLIST_PATH"; then
      echo "Generated GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_B64."
      return 0
    fi
    if printf '%s' "$GOOGLE_SERVICE_INFO_PLIST_B64" | grep -qi '<plist'; then
      printf '%s' "$GOOGLE_SERVICE_INFO_PLIST_B64" > "$IOS_PLIST_PATH"
      echo "GOOGLE_SERVICE_INFO_PLIST_B64 looked like raw plist; used as-is."
      return 0
    fi
    echo "Failed to decode GOOGLE_SERVICE_INFO_PLIST_B64."
    echo "Hint: regenerate with: base64 -i ios/Runner/GoogleService-Info.plist | tr -d '\\n'"
    exit 1
  fi

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

# Ensure Firebase plist exists before dependency work.
create_ios_google_service_info_plist

# Install Flutter only when unavailable.
if command -v flutter >/dev/null 2>&1; then
  log "Using preinstalled Flutter: $(flutter --version | head -n 1)"
else
  if [ ! -d "$HOME/flutter" ]; then
    log "Flutter not found. Cloning stable SDK into $HOME/flutter"
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
  log "Using cloned Flutter: $(flutter --version | head -n 1)"
fi

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
log "Running flutter precache --ios"
flutter precache --ios

# Install Flutter dependencies.
log "Running flutter pub get"
flutter pub get

# Sync pubspec.yaml version into project.pbxproj.
log "Running flutter build ios --release --config-only"
flutter build ios --release --config-only --dart-define="APP_ENV=$APP_ENV"

# Install CocoaPods only when unavailable.
if command -v pod >/dev/null 2>&1; then
  log "Using preinstalled CocoaPods: $(pod --version)"
else
  HOMEBREW_NO_AUTO_UPDATE=1
  log "CocoaPods not found. Installing via Homebrew"
  brew install cocoapods
fi

# Install CocoaPods dependencies.
log "Running pod install --repo-update"
cd ios && pod install --repo-update # run `pod install` in the `ios` directory.
log "ci_post_clone completed successfully"
