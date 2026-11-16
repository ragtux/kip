#!/usr/bin/env bash
# Build script for Pikchr WASM module
#
# Prerequisites:
# - Emscripten SDK (emcc)
# - wasi-stub (cargo install --git https://github.com/astrale-sharp/wasm-minimal-protocol wasi-stub)
# - git and a native C compiler (only needed when pikchr.c is not already
#   present: upstream no longer ships a pre-generated pikchr.c, so it is
#   generated from the Pikchr source tree)
#
# Environment:
#   PIKCHR_REPO  Pikchr git mirror to clone (default: github.com/drhsqlite/pikchr)
#   PIKCHR_REF   Branch or tag to build (default: master)
#   CC           Native C compiler used to build Pikchr's code generators (default: cc)

set -e
cd "$(dirname "$0")"

PIKCHR_REPO="${PIKCHR_REPO:-https://github.com/drhsqlite/pikchr}"
PIKCHR_REF="${PIKCHR_REF:-master}"
CC="${CC:-cc}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

fail() {
    echo -e "${RED}✗${NC}"
    echo "Error: $1"
    exit 1
}

echo "========================================="
echo "Pikchr WASM Build Script"
echo "========================================="

# Check prerequisites
echo -n "Checking for emcc... "
command -v emcc >/dev/null 2>&1 || fail "emcc not found. Please install Emscripten SDK.
Visit: https://emscripten.org/docs/getting_started/downloads.html"
echo -e "${GREEN}✓${NC} $(emcc --version | head -n1)"

echo -n "Checking for wasi-stub... "
command -v wasi-stub >/dev/null 2>&1 || fail "wasi-stub not found.
Install with: cargo install --git https://github.com/astrale-sharp/wasm-minimal-protocol wasi-stub"
echo -e "${GREEN}✓${NC}"

echo -n "Checking for pikchr_wasm.c... "
[ -f "pikchr_wasm.c" ] || fail "pikchr_wasm.c not found in $(pwd)."
echo -e "${GREEN}✓${NC}"

# Generate pikchr.c from the upstream source tree unless one is already here.
# (Delete pikchr.c to pick up a newer Pikchr.)
echo -n "Checking for pikchr.c... "
if [ -f "pikchr.c" ]; then
    echo -e "${GREEN}✓${NC} (using existing file)"
else
    echo "not found, generating from $PIKCHR_REPO ($PIKCHR_REF)"
    command -v git >/dev/null 2>&1 || fail "git not found (needed to fetch the Pikchr source)."
    command -v "$CC" >/dev/null 2>&1 || fail "C compiler '$CC' not found (set CC=...)."
    rm -rf pikchr-src
    git clone --quiet --depth 1 --branch "$PIKCHR_REF" "$PIKCHR_REPO" pikchr-src
    (
        cd pikchr-src
        # Same steps as the upstream Makefile's "pikchr.c" target
        "$CC" -o mkversion mkversion.c
        ./mkversion manifest.uuid manifest VERSION > VERSION.h
        "$CC" -o lemon lemon.c
        ./lemon pikchr.y
    )
    cp pikchr-src/pikchr.c pikchr.c
    echo -e "${GREEN}✓${NC} Generated pikchr.c ($(grep -o 'MANIFEST_ISODATE "[^"]*"' pikchr-src/VERSION.h || echo 'unknown version'))"
fi

# Clean previous builds
echo ""
echo "Cleaning previous builds..."
rm -f pikchr.wasm "pikchr - stubbed.wasm" "pikchr - stubbed (1).wasm" *.o

# Compile
echo ""
echo "Compiling with Emscripten..."
emcc pikchr.c pikchr_wasm.c \
  -O3 \
  --no-entry \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS="['_typst_pikchr','_typst_pikchr_dark']" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s STANDALONE_WASM=1 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -o pikchr.wasm
echo -e "${GREEN}✓${NC} Compilation successful"

# Stub WASI functions
echo ""
echo "Stubbing WASI functions..."
wasi-stub --stub-module wasi_snapshot_preview1 --stub-function env:emscripten_notify_memory_growth pikchr.wasm
echo -e "${GREEN}✓${NC} Stubbing successful"

# Find the stubbed file (wasi-stub creates "pikchr - stubbed.wasm" or numbered versions)
STUBBED_FILE=""
if [ -f "pikchr - stubbed.wasm" ]; then
    STUBBED_FILE="pikchr - stubbed.wasm"
elif [ -f "pikchr - stubbed (1).wasm" ]; then
    STUBBED_FILE="pikchr - stubbed (1).wasm"
fi

if [ -z "$STUBBED_FILE" ]; then
    echo -e "${RED}✗${NC} Could not find stubbed WASM file"
    exit 1
fi

# Copy to plugin directory
echo ""
echo "Installing to plugin directory..."
cp "$STUBBED_FILE" ../pikchr.wasm

# Get file size
SIZE=$(ls -lh ../pikchr.wasm | awk '{print $5}')

echo -e "${GREEN}✓${NC} Installation successful"
echo ""
echo "========================================="
echo -e "${GREEN}Build Complete!${NC}"
echo "========================================="
echo "WASM module size: $SIZE"
echo "Location: ../pikchr.wasm"
echo ""
echo "Test with:"
echo "  cd .."
echo "  typst compile example_simple.typ"
echo "========================================="
