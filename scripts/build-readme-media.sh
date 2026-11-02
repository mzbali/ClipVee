#!/bin/bash
# Converts native UI-test captures into the README GIF and app screenshots.
set -euo pipefail
task_root=$(cd "$(dirname "$0")/.." && pwd)
# The capture test logs where it saved its frames; pass a directory to use another capture.
capture_dir="${1:-}"
if [[ -z "$capture_dir" && -f "$task_root/.build/readme-capture.log" ]]; then
  capture_dir=$(rg -o 'README_CAPTURE_DIR=.*' "$task_root/.build/readme-capture.log" | tail -n 1 | cut -d= -f2-)
fi
[[ -n "$capture_dir" ]] || { echo "Usage: $0 [capture-directory]" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo 'Install ffmpeg to generate README media.' >&2; exit 1; }
for task_capture_file in frames.ffconcat panel.png settings.png; do
  test -f "$capture_dir/$task_capture_file" || { echo "Missing capture: $capture_dir/$task_capture_file" >&2; exit 1; }
done
mkdir -p "$task_root/docs/images" "$task_root/docs/screenshots"
# A window manager may tile the disposable editor across the whole display.
# Keep the document and clipboard region, without the unused right/bottom area.
crop_filter="crop=w='min(iw,2200)':h='min(ih,1300)':x=0:y=0"
ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$capture_dir/frames.ffconcat" \
  -filter_complex "$crop_filter,setpts=0.75*PTS,fps=8,scale=1000:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a:diff_mode=rectangle" \
  -loop 0 "$task_root/docs/images/demo.gif"
# The README shows the GIF; the website's panel picture is made from this screenshot.
ffmpeg -hide_banner -loglevel error -y -i "$capture_dir/panel.png" -vf "$crop_filter" \
  -frames:v 1 "$task_root/docs/screenshots/panel.png"
cp "$capture_dir/settings.png" "$task_root/docs/screenshots/settings.png"
printf 'Generated docs/images/demo.gif and updated panel/settings screenshots.\n'
