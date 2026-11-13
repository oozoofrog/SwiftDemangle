# SwiftDemangle

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Foozoofrog%2FSwiftDemangle%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/oozoofrog/SwiftDemangle)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Foozoofrog%2FSwiftDemangle%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/oozoofrog/SwiftDemangle)

# SwiftDemangle

## Overview

`SwiftDemangle` is a library designed for demangling Swift symbols, inspired by Swift's own `swift-demangle` tool. It follows the demangler of Swift 6.4.2, providing an easy-to-use interface for converting mangled Swift symbols into a human-readable format.

## What's New in 6.4.2

Synced with the Swift 6.4.2 demangler.

- **Output changes** (same symbols, new text, following upstream):
  - `read2` / `modify2` accessors print as `yielding_borrow` / `yielding_mutate`
  - `predefined @objc completion handler block implementation` prints as `checked @objc completion handler block implementation`
- **New manglings:** `borrow` / `mutate` accessors, `Builtin.Borrow<T>`, property wrapped field init accessors, `@caller_isolated` SIL function types, `@guaranteed_address` / `@guaranteed` / `@inout` SIL results, inverse requirements on associated types (`A.Element: ~Swift.Copyable`), `representation changed of` specializations
- **Function signature specializations:** constant propagated structs, chained constant propagation, escaping closure propagation and `Same As Argument N`
- **Node tree access:** `String.node` returns the demangled tree for read-only traversal (`kind`, `children`, `text`, `index`)
- **Nominal owner lookup:** `String.nominalOwner` returns the nominal type that owns a symbol, including type metadata, metaclass, value witness table and field offset symbols

## What's New in 6.0.4

- add swift package index documentation for swift 6.0

## What's New in 6.0.3

- remove binary target
- add xcframework.sh script to build xcframework

## What's New in 6.0.2

Version 6.0.2 of SwiftDemangle introduces significant updates and improvements, extending support for Swift's latest features. Key updates include:

- **Swift 6.0(6.1) Compatibility:** Full support for Swift 6.0 demangling features
- **Enhanced Generic Type Parsing:** Improved handling of complex generic type signatures
- **Async/Await Context Support:** Better parsing of async/await related symbols
- **Structured Concurrency Elements:** Support for structured concurrency related demangling
- **Improved Macro Support:** Extended capabilities for handling macro-generated code
- **Extended Platform Support:** Broader platform compatibility

## Installation

```Swift
# If using Swift Package Manager
dependencies: [
    .package(url: "https://github.com/oozoofrog/SwiftDemangle", .upToNextMajor(from: "6.4.2"))
]
```

## Usage

```Swift
import SwiftDemangle

// Example 1: Demangling a Builtin Vector Type
let mangledVector = "_TtBv4Bf16_"
let demangledVector = mangledVector.demangled
print(demangledVector)  // Output: Builtin.Vec4xFPIEEE16

// Example 2: Demangling a Protocol Descriptor
let mangledProtocol = "$ss6SimpleHr"
let demangledProtocol = mangledProtocol.demangled
print(demangledProtocol)  // Output: protocol descriptor runtime record for Swift.Simple

// Example 3: Finding the type that owns a symbol
let owner = "$s6Widget7ManagerC9operationyyF".nominalOwner
owner?.kind == .Class              // true
owner?.children.map(\.text)        // ["Widget", "Manager"]
```

`nominalOwner` returns `nil` for module-level declarations and for symbol shapes it does not support, such as protocol witnesses and reabstraction thunks.

## Build xcframework

```bash
./xcframework.sh
```

## Contributing

Contributions are welcome! If you have ideas for improvements or have found a bug, please feel free to fork the repository, make changes, and submit a pull request.

## License

SwiftDemangle is released under the Apache 2.0 License, ensuring compatibility with the original Swift swift-demangle source code's license terms. For more details, see the LICENSE file in the repository.
