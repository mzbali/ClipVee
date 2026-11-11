#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
task_temp=$(mktemp -d)
trap 'rm -rf "$task_temp"' EXIT
# This executable links only Foundation and value types, never the application.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swiftc -module-cache-path "$task_temp/ModuleCache" Maccy/Settings/SetupSummary.swift test-support/setup-summary/main.swift \
  -o "$task_temp/check-setup-summary"
"$task_temp/check-setup-summary"
