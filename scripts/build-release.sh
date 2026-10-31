#!/bin/bash
# Builds a Release copy of ClipVee and packages it as a disk image, a zip and an update feed
# (appcast.xml) for a GitHub release. Pass a Markdown file of release notes, which the app shows
# when it offers the update.
# Signed with the self-signed "ClipVee" certificate from create-signing-identity.sh, so macOS keeps
# the Accessibility permission across updates. Set CLIPVEE_RELEASE_IDENTITY=- to sign ad hoc instead.
set -euo pipefail
if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <release-notes.md>" >&2
  exit 1
fi
notes=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
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

# Xcode copies Sparkle's helpers with their ad hoc signatures. Sign each with the release
# identity, in the order Sparkle's documentation gives, then the framework and the app.
sparkle="$output/ClipVee.app/Contents/Frameworks/Sparkle.framework"
for code in Versions/B/XPCServices/Installer.xpc Versions/B/XPCServices/Downloader.xpc \
  Versions/B/Autoupdate Versions/B/Updater.app; do
  codesign -f -s "$identity" -o runtime --preserve-metadata=entitlements "$sparkle/$code"
done
codesign -f -s "$identity" -o runtime "$sparkle"
codesign -f -s "$identity" -o runtime --preserve-metadata=entitlements "$output/ClipVee.app"

codesign --verify --deep --strict "$output/ClipVee.app"
# Refuse to ship anything signed through Apple's certificate chain, such as a personal
# Apple Development certificate: those carry the developer's name and email.
find "$output/ClipVee.app" -name '*.app' -o -name '*.xpc' -o -name '*.framework' -o -name Autoupdate | while read -r code; do
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

# The app reads the feed from the latest release, so it lists only this version. generate_appcast
# signs the zip and the feed with the update key in your keychain (see LOCAL_DEVELOPMENT.md).
updates="$output/updates"
mkdir "$updates"
cp "$output/ClipVee-$version.zip" "$updates/"
cp "$notes" "$updates/ClipVee-$version.md"
.build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast --embed-release-notes \
  --download-url-prefix "https://github.com/mzbali/ClipVee/releases/download/v$version/" \
  --link https://mzbali.github.io/ClipVee/ --maximum-deltas 0 "$updates"
mv "$updates/appcast.xml" "$output/appcast.xml"
rm -rf "$updates"

echo "$output/ClipVee-$version.zip"
echo "$output/ClipVee-$version.dmg"
echo "$output/appcast.xml"
