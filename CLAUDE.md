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

- **Public API** (`String+Demangling.swift`): `String.demangled`, `String.demangling(_:)`, `String.node`, `String.nominalOwner`, `String.symbolKind`; read-only `Node` traversal: `kind`, `children`, `text`, `index`.
- **Nominal ownership** (`Node+NominalOwner.swift`): Follows supported declaration contexts and wrappers. Returns `nil` for module-level declarations and unsupported or ambiguous shapes; never searches arbitrary children or signature types as a fallback.
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
- `experimental-manglings.txt`: Test pairs for kinds that upstream `manglings.txt` does not cover; expected output comes from `swift-demangle`

The first three are copied unchanged from `test/Demangle/Inputs/` of the synced Swift release (currently `swift-6.4.2-RELEASE`).

### Extending

- New Node kinds: extend `Kind` enum in `Node.swift`
- New parsing rules: extend `demangleOperator()` in `Demangler.swift`
- New output formats: add switch cases in `printNode()` in `NodePrinter.swift`
- New options: add static properties to `DemangleOptions.swift`

### Syncing with a new Swift release

1. Diff `lib/Demangling`, `include/swift/Demangling` and `test/Demangle/Inputs` between the previous and the new `swift-*-RELEASE` tag.
2. Copy the three test input files, then port `DemangleNodes.def`, `Demangler.cpp`, `NodePrinter.cpp` and `OldDemangler.cpp` changes until `swift test` passes. `Remangler.cpp` has no counterpart here.
3. A new entity or accessor kind also goes into `isSimpleType` and `contexts` in `Node.swift`, into `nodeConsumesGenericArgs` in `Demangler.swift` when upstream lists it there, and into the switch in `Node+NominalOwner.swift`. The last two end in `default:`, so the compiler does not report a missing kind.
4. Compare against the toolchain: `xcrun swift-demangle < symbols.txt` on symbols taken with `nm` from Swift binaries. Xcode's tool also knows manglings that are not in the open-source tag (`Md`, `MR`); those are not ported.
5. Record the changes in `Diff.md` and `README.md`.

## Conventions

- Uses Swift 6.0 strict concurrency mode (`swiftLanguageModes: [.v6]`)
- Split files exceeding 500 lines
