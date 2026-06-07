#!/usr/bin/env bash
set -euo pipefail

EXPECTED_VERSION="v18-safe-waitany-direct-input"

rm -rf build_vasm
rm -f *.o Gloom Gloom2 Gloom_ap

echo "Checking required tools..."
for tool in vasmm68k_mot vlink python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: required tool not found: $tool" >&2
        exit 1
    fi
    echo "OK: $tool"
done

echo "Checking source files..."
for file in gloom.s GenAm.opts tools/normalize_gloom_source.py VERSION.txt; do
    if [ ! -f "$file" ]; then
        echo "ERROR: required file not found: $file" >&2
        exit 1
    fi
    echo "OK: $file"
done

echo "Checking wrapper version..."
CURRENT_VERSION="$(cat VERSION.txt | tr -d '\r\n')"
if [ "$CURRENT_VERSION" != "$EXPECTED_VERSION" ]; then
    echo "ERROR: wrong wrapper version: $CURRENT_VERSION" >&2
    echo "Expected: $EXPECTED_VERSION" >&2
    exit 1
fi
echo "OK: $EXPECTED_VERSION"

make SRC=gloom.s OUT=Gloom build-one
