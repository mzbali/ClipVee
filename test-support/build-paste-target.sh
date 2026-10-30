#!/bin/bash
set -euo pipefail
task_root=$(cd "$(dirname "$0")/.." && pwd)
task_app="$task_root/.build/PasteTarget.app"
mkdir -p "$task_app/Contents/MacOS"
cat > "$task_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>uk.co.mzbali.MaccyPasteTarget</string>
<key>CFBundleExecutable</key><string>PasteTarget</string>
<key>CFBundleName</key><string>Maccy Paste Target</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
swiftc "$task_root/test-support/PasteTarget.swift" -o "$task_app/Contents/MacOS/PasteTarget"
codesign --force --sign - "$task_app"
