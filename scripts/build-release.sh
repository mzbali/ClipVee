#!/bin/bash
# Builds a Release copy of ClipVee and packages it as a disk image and a zip for a GitHub release.
# Signed with the self-signed "ClipVee" certificate from create-signing-identity.sh, so macOS keeps
# the Accessibility permission across updates. Set CLIPVEE_RELEASE_IDENTITY=- to sign ad hoc instead.
set -euo pipefail
task_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$task_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

version=$(xcodebuild -project Maccy.xcodeproj -target Maccy -configuration Release -showBuildSettings 2>/dev/null |
  awk '/ MARKETING_VERSION = / { print $3; exit }')
output="$task_root/.build/release"
identity="${CLIPVEE_RELEASE_IDENTITY:-ClipVee}"
if [ "$identity" != "-" ] && ! security find-certificate -c "$identity" >/dev/null 2>&1; then
  echo "No \"$identity\" certificate in your keychain. Run scripts/create-signing-identity.sh first." >&2
  exit 1
fi
rm -rf "$output"

xcodebuild -project Maccy.xcodeproj -scheme ClipVee -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath .build/ReleaseDerivedData \
  -clonedSourcePackagesDirPath .build/SourcePackages -skipPackageUpdates \
  CODE_SIGN_IDENTITY="$identity" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  CONFIGURATION_BUILD_DIR="$output" \
  build

codesign --verify --deep --strict "$output/ClipVee.app"
# Refuse to ship anything signed through Apple's certificate chain, such as a personal
# Apple Development certificate: those carry the developer's name and email.
find "$output/ClipVee.app" -name '*.app' -o -name '*.xpc' -o -name '*.framework' | while read -r code; do
  if codesign -dvv "$code" 2>&1 | grep -q '^Authority=Apple'; then
    echo "$code is signed with an Apple-issued certificate." >&2
    exit 1
  fi
done
if codesign -d --entitlements - "$output/ClipVee.app" 2>/dev/null | grep -q get-task-allow; then
  echo "The release build allows debugging (get-task-allow)." >&2
  exit 1
fi
ditto -c -k --sequesterRsrc --keepParent "$output/ClipVee.app" "$output/ClipVee-$version.zip"

# The disk image opens as a window with an arrow from ClipVee to Applications.
dmg_tools="$task_root/.build/dmg-venv"
if [ ! -x "$dmg_tools/bin/dmgbuild" ]; then
  python3 -m venv "$dmg_tools"
  "$dmg_tools/bin/pip" install --quiet dmgbuild
fi
"$dmg_tools/bin/dmgbuild" -s scripts/dmg-settings.py \
  -D app="$output/ClipVee.app" -D background=Design/dmg-background.png \
  ClipVee "$output/ClipVee-$version.dmg"

echo "$output/ClipVee-$version.zip"
echo "$output/ClipVee-$version.dmg"
