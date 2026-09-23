#!/usr/bin/env bash
set -euo pipefail
root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
base_ref=${1:-HEAD}
benchmark_dir=$(mktemp -d)
trap 'rm -rf -- "$benchmark_dir"' EXIT
mkdir -p -- "$benchmark_dir/before" "$benchmark_dir/after"
for file in LayoutModel.js GroupIcons.js LucideIcons.js LucideKeywords.js; do
  git -C "$root_dir" show "$base_ref:$file" > "$benchmark_dir/before/$file"
  cp -- "$root_dir/$file" "$benchmark_dir/after/$file"
done
cp -- "$root_dir/tests/fixtures/benchmark.qml" "$benchmark_dir/shell.qml"
# Use Qt's JavaScript engine without connecting to the desktop or GPU.
env -u WAYLAND_DISPLAY QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  timeout 30 quickshell -p "$benchmark_dir" --no-color
