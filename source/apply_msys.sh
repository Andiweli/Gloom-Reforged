#!/usr/bin/env bash
set -euo pipefail

WRAP_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"

if [ ! -f "$PROJECT_DIR/gloom.s" ]; then
    echo "ERROR: run this from the GloomAmiga repository folder that contains gloom.s" >&2
    exit 1
fi

mkdir -p "$PROJECT_DIR/tools"
cp -f "$WRAP_DIR/Makefile" "$PROJECT_DIR/Makefile"
cp -f "$WRAP_DIR/build_msys.sh" "$PROJECT_DIR/build_msys.sh"
cp -f "$WRAP_DIR/tools/normalize_gloom_source.py" "$PROJECT_DIR/tools/normalize_gloom_source.py"
cp -f "$WRAP_DIR/VERSION.txt" "$PROJECT_DIR/Gloom_BuildWrapper_VERSION.txt"
chmod +x "$PROJECT_DIR/build_msys.sh"

echo "Applied Gloom_BuildWrapper $(tr -d '\r\n' < "$WRAP_DIR/VERSION.txt")"
