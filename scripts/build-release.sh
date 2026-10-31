#!/bin/bash
# Builds a Release copy of ClipVee and zips it for a GitHub release.
# Always signed ad hoc, so no personal certificate details end up in the download.
set -euo pipefail
task_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$task_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

version=$(xcodebuild -project Maccy.xcodeproj -target Maccy -configuration Release -showBuildSettings 2>/dev/null |
  awk '/ MARKETING_VERSION = / { print $3; exit }')
output="$task_root/.build/release"
rm -rf "$output"

xcodebuild -project Maccy.xcodeproj -scheme ClipVee -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath .build/ReleaseDerivedData \
  -clonedSourcePackagesDirPath .build/SourcePackages -skipPackageUpdates \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  CONFIGURATION_BUILD_DIR="$output" \
  build

codesign --verify --deep --strict "$output/ClipVee.app"
ditto -c -k --sequesterRsrc --keepParent "$output/ClipVee.app" "$output/ClipVee-$version.zip"
echo "$output/ClipVee-$version.zip"
