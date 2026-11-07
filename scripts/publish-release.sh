#!/bin/bash
# Publishes the release that build-release.sh wrote to .build/release: creates the GitHub release
# tagged v<version> from main, checks the update feed users get, and opens a pull request in
# mzbali/homebrew-tap that bumps the cask. Signing stays local; nothing secret leaves this Mac.
set -euo pipefail
task_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$task_root"

version=$(awk '/MARKETING_VERSION = / { gsub(";", "", $3); print $3; exit }' Maccy.xcodeproj/project.pbxproj)
release=".build/release"
notes="docs/releases/$version.md"
files=("$release/ClipVee-$version.dmg" "$release/ClipVee-$version.zip" "$release/appcast.xml")
for f in "$notes" "${files[@]}"; do
  [ -f "$f" ] || { echo "Missing $f. Write the notes and run scripts/build-release.sh first." >&2; exit 1; }
done
# Rerunning after a failure later on resumes from the existing release.
if gh release view "v$version" >/dev/null 2>&1; then
  echo "v$version is already released; finishing the remaining steps."
else
  git fetch -q origin main
  if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
    echo "Release from merged code: check out main at origin/main, rebuild, then run this again." >&2
    exit 1
  fi
  gh release create "v$version" "${files[@]}" --target "$(git rev-parse HEAD)" \
    --title "ClipVee $version" --notes-file "$notes" --latest
fi

# Hash the disk image users download, not the local copy.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
gh release download "v$version" --pattern "ClipVee-$version.dmg" --dir "$tmp"
sha=$(shasum -a 256 "$tmp/ClipVee-$version.dmg" | awk '{ print $1 }')

feed=$(curl -fsSL https://github.com/mzbali/ClipVee/releases/latest/download/appcast.xml)
zip_size=$(stat -f %z "$release/ClipVee-$version.zip")
grep -q "sparkle:shortVersionString>$version<" <<<"$feed" || { echo "appcast.xml does not list $version yet." >&2; exit 1; }
grep -q "length=\"$zip_size\"" <<<"$feed" || { echo "appcast.xml length does not match the zip ($zip_size bytes)." >&2; exit 1; }

gh repo clone mzbali/homebrew-tap "$tmp/tap" -- -q
cd "$tmp/tap"
if grep -q "^  version \"$version\"" Casks/clipvee.rb; then
  echo "The cask is already at $version."
  exit 0
fi
if git ls-remote --exit-code -q origin "clipvee-$version" >/dev/null; then
  gh pr view "clipvee-$version" --json url --jq '"The cask bump is already open: \(.url)"'
  exit 0
fi
git switch -q -c "clipvee-$version"
sed -i '' -E "s/^  version \".*\"/  version \"$version\"/; s/^  sha256 \".*\"/  sha256 \"$sha\"/" Casks/clipvee.rb
git commit -qam "Update ClipVee to $version"
git push -q -u origin "clipvee-$version"
gh pr create --title "Update ClipVee to $version" \
  --body "Bumps the cask to the [v$version release](https://github.com/mzbali/ClipVee/releases/tag/v$version). The sha256 is from the disk image downloaded back from the release. CI's online audit downloads it again and checks the hash."
