# Building the Pikchr WASM Module

This guide explains how to rebuild the `pikchr.wasm` module from source.

## Prerequisites

You'll need:

1. **Pikchr Source Code** - Download from [pikchr.org](https://pikchr.org) or clone from the [Fossil repository](https://pikchr.org/home/timeline)
2. **Emscripten SDK** - For compiling C to WebAssembly
3. **Rust and Cargo** - For the `wasi-stub` tool (to remove WASI dependencies)

## Quick Build (Recommended)

If you already have the prerequisites installed:

```bash
# 1. Get pikchr source
# Download pikchr.c from https://pikchr.org/home/file/pikchr.c

# 2. Compile to WASM with Emscripten
emcc pikchr.c pikchr_wasm.c \
  -O3 --no-entry \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS="['_typst_pikchr']" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s STANDALONE_WASM=1 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -o pikchr.wasm

# 3. Stub WASI functions
wasi-stub --stub-function env:emscripten_notify_memory_growth pikchr.wasm

# 4. Copy to plugin directory
cp "pikchr - stubbed.wasm" ../pikchr.wasm
```

## Detailed Setup Instructions

### Step 1: Install Emscripten

**Option A: Using emsdk (Recommended)**

```bash
# Clone the Emscripten SDK
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk

# Install and activate the latest version
./emsdk install latest
./emsdk activate latest

# Set up environment (run this in each new terminal)
source ./emsdk_env.sh  # On Linux/Mac
# OR
emsdk_env.bat         # On Windows
```

**Option B: Using Package Manager**

```bash
# On Windows with winget
winget install emscripten

# On macOS with Homebrew
brew install emscripten

# On Linux (Ubuntu/Debian)
sudo apt-get install emscripten
```

### Step 2: Install wasi-stub

The `wasi-stub` tool removes WASI system interface imports that Typst doesn't support.

```bash
# Install from the wasm-minimal-protocol repository
cargo install --git https://github.com/astrale-sharp/wasm-minimal-protocol wasi-stub
```

### Step 3: Get Pikchr Source

Download the pikchr.c file:

```bash
# Option 1: Direct download
curl -o pikchr.c https://pikchr.org/home/file/pikchr.c

# Option 2: Clone the entire repository
git clone https://github.com/drhsql/pikchr.git
# Note: pikchr.c needs to be generated from pikchr.y using lemon parser generator
```

### Step 4: Build the WASM Module

Place `pikchr.c` and `pikchr_wasm.c` (from this directory) in the same folder, then:

```bash
# Compile with Emscripten
emcc pikchr.c pikchr_wasm.c \
  -O3 \
  --no-entry \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS="['_typst_pikchr']" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s STANDALONE_WASM=1 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -o pikchr.wasm

# Stub WASI imports to make it compatible with Typst
wasi-stub --stub-function env:emscripten_notify_memory_growth pikchr.wasm

# The stubbed file will be named "pikchr - stubbed.wasm"
# Copy it to replace the original in the plugin directory
cp "pikchr - stubbed.wasm" ../pikchr.wasm
```

### Step 5: Test the Plugin

```bash
# Navigate to plugin directory
cd ..

# Test with example
typst compile example_simple.typ

# Check that the PDF was created
ls -lh example_simple.pdf
```

## Build Script (Optional)

Create a `build.sh` script for easier rebuilding:

```bash
#!/bin/bash
set -e

echo "Building Pikchr WASM plugin..."

# Check prerequisites
command -v emcc >/dev/null 2>&1 || { echo "Error: emcc not found. Install Emscripten first."; exit 1; }
command -v wasi-stub >/dev/null 2>&1 || { echo "Error: wasi-stub not found. Install it with: cargo install wasi-stub"; exit 1; }

# Compile
echo "Compiling with Emscripten..."
emcc pikchr.c pikchr_wasm.c \
  -O3 --no-entry \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS="['_typst_pikchr']" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s STANDALONE_WASM=1 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -o pikchr.wasm

# Stub WASI functions
echo "Stubbing WASI functions..."
wasi-stub --stub-function env:emscripten_notify_memory_growth pikchr.wasm

# Copy to plugin directory
echo "Installing to plugin directory..."
cp "pikchr - stubbed.wasm" ../pikchr.wasm

echo "✓ Build complete! WASM module is ready."
echo "  Size: $(ls -lh ../pikchr.wasm | awk '{print $5}')"
```

## Understanding the Build Process

### Why Emscripten?

Pikchr is written in C and uses standard library functions (malloc, string.h, etc.). Emscripten provides:
- Full C standard library implementation
- WebAssembly compilation toolchain
- Optimized output suitable for browser/standalone environments

### Why wasi-stub?

Emscripten-compiled WASM includes WASI (WebAssembly System Interface) imports for system-level functions. Typst's WASM runtime doesn't provide these functions, so we use `wasi-stub` to replace them with no-op stubs.

The stubbed functions:
- `wasi_snapshot_preview1::proc_exit`
- `wasi_snapshot_preview1::fd_close`
- `wasi_snapshot_preview1::fd_write`
- `wasi_snapshot_preview1::fd_seek`
- `env::emscripten_notify_memory_growth`

### The Wrapper Code

`pikchr_wasm.c` implements the Typst plugin protocol:

1. **Input**: Takes Pikchr markup as a byte buffer (with length parameter)
2. **Processing**: Calls the pikchr() C function to generate SVG
3. **Output**: Returns SVG as bytes using the wasm-minimal-protocol

Key protocol functions:
- `wasm_minimal_protocol_write_args_to_buffer()` - Receives input from Typst
- `wasm_minimal_protocol_send_result_to_host()` - Sends output back to Typst

## Troubleshooting

### "Error: emcc not found"
Make sure you've activated the Emscripten environment:
```bash
source ./emsdk/emsdk_env.sh  # or emsdk_env.bat on Windows
```

### "Error: wasi-stub not found"
Install it with:
```bash
cargo install --git https://github.com/astrale-sharp/wasm-minimal-protocol wasi-stub
```

### "cannot find definition for import..."
This means WASI functions weren't properly stubbed. Make sure you ran the wasi-stub command and copied the stubbed output.

### Build succeeds but Typst gives "failed to parse SVG"
Check that:
1. You're using the stubbed WASM file (not the original)
2. The pikchr_wasm.c file is the correct version (using wasm-minimal-protocol)
3. Emscripten version is reasonably recent (tested with 3.1.46 and 4.0.21)

## References

- [Pikchr Source](https://pikchr.org/home/file/pikchr.c)
- [Emscripten Documentation](https://emscripten.org/docs/getting_started/downloads.html)
- [wasm-minimal-protocol](https://github.com/astrale-sharp/wasm-minimal-protocol)
- [Typst Plugin Documentation](https://typst.app/docs/reference/foundations/plugin/)
- [diagraph build process](https://github.com/Robotechnic/diagraph) - Reference implementation

## Version Information

- **Emscripten**: Tested with 3.1.46 and 4.0.21
- **Pikchr**: Compatible with latest version from pikchr.org
- **Typst**: Tested with 0.12.0+
- **wasi-stub**: 0.2.0+
