# Repository Structure - Kip

This document explains the organization of the **Kip** (Pikchr for Typst) plugin repository.

## Directory Layout

```
kip/
├── README.md              # Main documentation
├── LICENSE                # MIT License
├── CHANGELOG.md           # Version history
├── STRUCTURE.md           # This file
├── QUICK_START.md         # 5-minute getting started guide
├── .gitignore            # Git ignore rules
│
├── typst.toml            # Typst package manifest
├── lib.typ               # Main plugin code
├── pikchr.wasm           # Compiled WebAssembly module (~125KB)
├── example_simple.typ    # Working examples
│
└── build-scripts/        # Build tools (for WASM recompilation)
    ├── BUILD.md          # Detailed build instructions
    ├── build.sh          # Unix/Linux/Mac build script
    ├── build.bat         # Windows build script
    └── pikchr_wasm.c     # C wrapper implementing Typst plugin protocol
```

## Core Files

### Plugin Files (Required)

These files are essential for the plugin to function:

- **`lib.typ`** - The main Typst interface (~2KB)
  - Exports `kip()` as the primary function
  - Provides `pikchr()` and `render()` aliases
  - Handles raw block and string inputs
  - Converts WASM output to Typst images

- **`pikchr.wasm`** - The WebAssembly module (~125KB)
  - Contains the compiled Pikchr C library
  - Optimized with -O3
  - Stubbed to remove WASI dependencies

- **`typst.toml`** - Package manifest (~1KB)
  - Package name: "kip"
  - Version, authors, dependencies
  - Exclusion rules for build artifacts

### Documentation Files

- **`README.md`** - User-facing documentation
  - Installation instructions
  - Usage examples with kip()
  - API reference
  - Background on the name

- **`QUICK_START.md`** - 5-minute tutorial
  - Fast installation
  - First diagram
  - Common patterns

- **`CHANGELOG.md`** - Version history
  - Changes between versions
  - Breaking changes
  - Planned features

- **`LICENSE`** - MIT License
  - Applies to Kip wrapper code
  - Notes about Pikchr's BSD license

- **`STRUCTURE.md`** - This file
  - Repository organization
  - File purposes

### Example Files

- **`example_simple.typ`** - Working examples
  - Tested, working diagrams
  - Demonstrates various features
  - Uses `kip()` function
  - Can be compiled directly

## Build Scripts Directory

The `build-scripts/` directory contains everything needed to rebuild the WASM module:

### Documentation

- **`BUILD.md`** - Comprehensive build guide
  - Prerequisites and setup
  - Step-by-step instructions
  - Troubleshooting

### Build Tools

- **`build.sh`** - Unix build script
  - Automated build process
  - Prerequisite checking
  - Error handling

- **`build.bat`** - Windows build script
  - Same as build.sh but for Windows
  - CMD/PowerShell compatible

### Source Code

- **`pikchr_wasm.c`** - WASM wrapper (~2KB)
  - Implements wasm-minimal-protocol
  - Bridges Pikchr C library and Typst
  - Handles input/output conversion

### External Dependencies (Not Included)

To rebuild the WASM module, you'll need to obtain:

- **`pikchr.c`** - Download from [pikchr.org](https://pikchr.org/home/file/pikchr.c)
  - The main Pikchr library
  - ~286KB of C code
  - Not included to keep repository clean

## What's NOT Included

The following are intentionally excluded from the plugin repository:

### Pikchr Source Files
- `pikchr.c` - Download separately from pikchr.org
- `pikchr.h` - Generated during pikchr build
- `pikchr.y` - Grammar file (source for pikchr.c)
- `lemon.c` - Parser generator
- Other pikchr build tools

### Build Artifacts
- `*.o`, `*.obj` - Object files
- `*.exe` - Executables
- Temporary WASM files

### External Tools
- `emsdk/` - Emscripten SDK
- `wasm-minimal-protocol/` - Rust crates
- Development tools

### Test Files
- `test_*.typ` - Development test files
- Generated PDFs from examples

## File Size Summary

```
lib.typ                ~2KB    Typst code (with kip function)
pikchr.wasm          ~125KB    Compiled module
pikchr_wasm.c          ~2KB    C wrapper
example_simple.typ     ~1KB    Examples
README.md              ~4KB    Documentation
typst.toml             ~1KB    Manifest

Total (core files):   ~135KB
```

## Version Control

### What to Commit

✅ Commit these files:
- All documentation (*.md)
- Plugin code (lib.typ)
- Compiled WASM (pikchr.wasm)
- Build scripts (build-scripts/*.sh, *.bat)
- WASM wrapper source (pikchr_wasm.c)
- Package manifest (typst.toml)
- Examples (example_simple.typ)
- License files

❌ Don't commit:
- Generated PDFs
- Build artifacts (*.o, *.obj)
- Pikchr source (pikchr.c) - users download separately
- Test files
- Editor configs
- Temporary files

### .gitignore

The `.gitignore` file excludes:
- Build artifacts
- Test files and PDFs
- Editor files
- Temporary files
- Downloaded source files in build-scripts/

## For Plugin Users

If you're just using the plugin, you only need:
- `lib.typ`
- `pikchr.wasm`
- `typst.toml`

Then import with:
```typst
#import "@local/kip:0.1.0": kip
```

## For Plugin Developers

If you're modifying or rebuilding the plugin:

1. Clone the repository
2. Follow `build-scripts/BUILD.md` to set up build tools
3. Download `pikchr.c` to `build-scripts/`
4. Run `build.sh` or `build.bat` to rebuild WASM
5. Test with `typst compile example_simple.typ`

## Naming

### Why "Kip"?

Kip is "Pik" (from Pikchr) backwards - a playful nod to the library while being:
- ✅ Short and memorable
- ✅ Easy to type
- ✅ Compliant with Typst package naming rules
- ✅ Unique and distinctive

### Function Names

- **`kip()`** - Primary function name
- **`pikchr()`** - Alias for users familiar with Pikchr
- **`render()`** - Generic alias

All three work identically!

## Separation from Pikchr Source

This plugin repository is intentionally kept separate from the Pikchr source code:

**Benefits:**
- Small repository size (~135KB vs several MB)
- Clear separation of concerns
- Easier maintenance
- Users don't need full Pikchr build system
- Respects Pikchr's BSD license while using MIT for wrapper

**Trade-offs:**
- Need to download pikchr.c separately to rebuild
- Must keep pikchr.c version documented
- Requires external build tools (Emscripten)

This approach follows the pattern used by other successful Typst plugins like [diagraph](https://github.com/Robotechnic/diagraph).
