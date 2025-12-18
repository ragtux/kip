#!/bin/bash
# Build script for Pikchr WASM module
#
# Prerequisites:
# - Emscripten SDK (emcc)
# - wasi-stub (cargo install wasi-stub)
# - pikchr.c (download from pikchr.org)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Pikchr WASM Build Script"
echo "========================================="

# Check prerequisites
echo -n "Checking for emcc... "
if ! command -v emcc >/dev/null 2>&1; then
    echo -e "${RED}✗${NC}"
    echo "Error: emcc not found. Please install Emscripten SDK."
    echo "Visit: https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi
echo -e "${GREEN}✓${NC} $(emcc --version | head -n1)"

echo -n "Checking for wasi-stub... "
if ! command -v wasi-stub >/dev/null 2>&1; then
    echo -e "${RED}✗${NC}"
    echo "Error: wasi-stub not found."
    echo "Install with: cargo install --git https://github.com/astrale-sharp/wasm-minimal-protocol wasi-stub"
    exit 1
fi
echo -e "${GREEN}✓${NC}"

echo -n "Checking for pikchr.c... "
if [ ! -f "pikchr.c" ]; then
    echo -e "${RED}✗${NC}"
    echo "Error: pikchr.c not found in current directory."
    echo "Download from: https://pikchr.org/home/file/pikchr.c"
    exit 1
fi
echo -e "${GREEN}✓${NC}"

echo -n "Checking for pikchr_wasm.c... "
if [ ! -f "pikchr_wasm.c" ]; then
    echo -e "${RED}✗${NC}"
    echo "Error: pikchr_wasm.c not found in current directory."
    exit 1
fi
echo -e "${GREEN}✓${NC}"

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
  -s EXPORTED_FUNCTIONS="['_typst_pikchr']" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s STANDALONE_WASM=1 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -o pikchr.wasm

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Compilation failed"
    exit 1
fi
echo -e "${GREEN}✓${NC} Compilation successful"

# Stub WASI functions
echo ""
echo "Stubbing WASI functions..."
wasi-stub --stub-function env:emscripten_notify_memory_growth pikchr.wasm

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Stubbing failed"
    exit 1
fi
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

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Installation failed"
    exit 1
fi

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
