# Quick Start Guide - Kip

Get started with **Kip**, the Pikchr plugin for Typst, in 5 minutes!

## 1. Install the Plugin

### Option A: Typst Universe (Fastest)

Nothing to install - just import it:

```typst
#import "@preview/kip:0.2.0": kip
```

### Option B: Direct Use

Place the `kip` directory next to your Typst document:

```
your-project/
├── kip/  (this plugin)
│   ├── lib.typ
│   ├── pikchr.wasm
│   └── ...
└── your-document.typ
```

### Option C: System Installation

Copy to your Typst packages directory:

**Windows:**
```powershell
xcopy /E /I kip "%APPDATA%\typst\packages\local\kip\0.2.0"
```

**Linux/Mac:**
```bash
mkdir -p ~/.local/share/typst/packages/local/kip/0.2.0
cp -r kip/* ~/.local/share/typst/packages/local/kip/0.2.0/
```

## 2. Create Your First Diagram

Create a file `test.typ`:

```typst
// Option A: From Typst Universe
#import "@preview/kip:0.2.0": kip

// Option B: Direct import (if plugin is next to your file)
// #import "kip/lib.typ": kip

// Option C: System import (if installed to packages directory)
// #import "@local/kip:0.2.0": kip

= My First Kip Diagram

#kip(```
box "Start"
arrow
circle "End" fit
```)
```

## 3. Compile

```bash
typst compile test.typ
```

Open `test.pdf` to see your diagram!

## Common Diagram Patterns

### Flow Chart

```typst
#kip(```
box "Start" rad 15px fit
arrow down
box "Process" fit
arrow down
diamond "Decision?" fit
arrow right "Yes" above from last diamond.e
box "Action A" fit
arrow down "No" from last diamond.s
box "Action B" fit
```)
```

### State Machine

```typst
#kip(```
circle "Idle" fit
arrow right 150% "event" above
circle "Active" fit
arrow right 150% "done" above
circle "Complete" fit
```)
```

### Architecture Diagram

```typst
#kip(```
box "Frontend" width 3cm fit
arrow down 50%
box "API Layer" width 3cm fit
arrow down 50%
box "Database" width 3cm fill lightblue fit
```)
```

### Sequence Flow

```typst
#kip(```
arrow right 200% "Request"
box "Server" fit
arrow right 200% "Response"
```)
```

## Customization

### With Sizing

```typst
#kip(
  ```box "Hello" arrow circle "World" fit```,
  width: 300pt
)
```

### Dark Mode

```typst
#block(fill: black, inset: 10pt, kip(dark: true, "box \"Dark\""))
```

### Using Strings

```typst
#kip("box \"Direct String\"")
```

## Function Aliases

You can use any of these - they all work the same:

```typst
#import "@local/kip:0.2.0": kip, pikchr, render

#kip("box \"A\"")      // Primary name
#pikchr("box \"B\"")   // Familiar to Pikchr users
#render("box \"C\"")   // Generic name
```

## Next Steps

- 📖 Read [README.md](README.md) for complete documentation
- 🎨 See [example_simple.typ](example_simple.typ) for more patterns
- 📚 Learn Pikchr syntax at [pikchr.org](https://pikchr.org)

## Troubleshooting

### "unknown font family"
This is just a warning, not an error. Install the font or use a different one:
```typst
#set text(font: "Arial")  // or any font you have
```

### "plugin errored with: ..."
Your Pikchr markup has a syntax error. The message shows the offending line
with a `^` marker under the token Pikchr could not understand.

### "cannot find definition for import"
The WASM file has WASI dependencies. Use the pre-compiled `pikchr.wasm` from this package, or rebuild following [build-scripts/BUILD.md](build-scripts/BUILD.md).

## Getting Help

- Check [README.md](README.md) for detailed docs
- Review [example_simple.typ](example_simple.typ) for working examples
- Visit [pikchr.org](https://pikchr.org) for Pikchr language reference

## That's It!

You're ready to create beautiful diagrams in Typst with Kip. Happy diagramming! 🎨

> **Why "Kip"?** It's "Pik" backwards - a playful nod to the Pikchr language!
