#!/bin/bash
# Copies clipboard history and settings from Maccy (or another build of it) into ClipVee.
# Usage: scripts/migrate-history.sh [source-bundle-id]   (default: org.p0deje.Maccy)
set -euo pipefail

source_id="${1:-org.p0deje.Maccy}"
target_id="${CLIPVEE_BUNDLE_ID:-uk.co.mzbali.ClipVee}"
containers="$HOME/Library/Containers"
source_data="$containers/$source_id/Data/Library/Application Support/Maccy"
target_data="$containers/$target_id/Data/Library/Application Support/Maccy"

if [[ ! -f "$source_data/Storage.sqlite" ]]; then
  echo "No history found for $source_id." >&2
  exit 1
fi
if [[ ! -d "$containers/$target_id" ]]; then
  echo "Open ClipVee once and quit it, then run this again." >&2
  exit 1
fi
for id in "$source_id" "$target_id"; do
  if [[ "$(osascript -e "application id \"$id\" is running" 2>/dev/null)" == "true" ]]; then
    echo "Quit $id first." >&2
    exit 1
  fi
done

if [[ -e "$target_data" ]]; then
  backup="$target_data.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$target_data" "$backup"
  echo "Moved ClipVee's existing history to $backup"
fi
mkdir -p "$target_data"
cp -p "$source_data"/Storage.sqlite* "$target_data/"

defaults export "$source_id" - | defaults import "$target_id" -

echo "Copied history and settings from $source_id to $target_id."
echo "Open ClipVee, then allow it in System Settings → Privacy & Security → Accessibility."
