# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
swift build              # Build
swift test               # Run all tests
swift test --filter SwiftDemangleTests/testManglings   # Run a single test
swift test --filter SwiftDemangle6Tests    # Run Swift 6 tests only
swift test --filter SymbolKindTests        # Run symbol kind tests only
```

## Architecture

A Swift symbol demangling library. Converts mangled Swift symbols into human-readable form. Pure Swift reimplementation of the Swift compiler's `swift-demangle` with zero external dependencies.

### Demangling Pipeline

```
mangled string → Demangler or OldDemangler → Node tree → NodePrinter → demangled string
```

- **Public API** (`String+Demangling.swift`): `String.demangled`, `String.demangling(_:)`, `String.symbolKind`
- **Demangler** (`Demangler.swift`): Handles modern mangling (`$s`, `$S` prefixes). Stack-based iterative parsing
- **OldDemangler** (`OldDemangler.swift`): Handles legacy `_T` prefix. Recursive descent parsing
- **Demanglerable protocol** (`Demanglerable.swift`): Low-level parsing interface shared by both demanglers (`peekChar`, `nextChar`, `nextIf`, etc.)
- **Demangling protocol** (`Demangling.swift`): Routes to Demangler or OldDemangler based on prefix
- **Node** (`Node.swift`): AST node. Composed of `Kind` enum (150+ variants) and `Payload` enum
- **NodePrinter** (`NodePrinter.swift`): Converts Node tree to string. Defines output rules via per-Kind switch cases
- **DemangleOptions**: `OptionSet`-based. Provides preset combinations like `defaultOptions` and `simplifiedOptions`

### Tests

Test data lives in `Tests/SwiftDemangleTests/Resources/` as text files:
- `manglings.txt`: Test pairs in `mangled ---> demangled` format
- `simplified-manglings.txt`: Test pairs using `simplifiedOptions`
- `manglings-with-clang-types.txt`: Test pairs including Clang types

### Extending

- New Node kinds: extend `Kind` enum in `Node.swift`
- New parsing rules: extend `demangleOperator()` in `Demangler.swift`
- New output formats: add switch cases in `printNode()` in `NodePrinter.swift`
- New options: add static properties to `DemangleOptions.swift`

## Conventions

- Uses Swift 6.0 strict concurrency mode (`swiftLanguageModes: [.v6]`)
- Split files exceeding 500 lines
