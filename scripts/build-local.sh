#!/bin/bash
set -euo pipefail
task_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$task_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Debug \
  -derivedDataPath .build/DerivedData \
  -clonedSourcePackagesDirPath .build/SourcePackages -skipPackageUpdates \
  CODE_SIGN_IDENTITY="${MACCY_SIGN_IDENTITY:--}" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  build-for-testing
./test-support/build-paste-target.sh
