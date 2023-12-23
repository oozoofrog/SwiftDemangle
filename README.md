# SwiftDemangle

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Foozoofrog%2FSwiftDemangle%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/oozoofrog/SwiftDemangle)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Foozoofrog%2FSwiftDemangle%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/oozoofrog/SwiftDemangle)

# SwiftDemangle

## Overview

`SwiftDemangle` is a library designed for demangling Swift symbols, inspired by Swift's own `swift-demangle` tool. This library offers compatibility up to Swift version 5.9, providing an easy-to-use interface for converting mangled Swift symbols into a human-readable format.

## What's New in 5.9.1

Version 5.9.1 of SwiftDemangle brings several exciting enhancements, extending support for Swift's latest 5.9 demangle grammar. Key updates include:

- **Builtin Vector and Floating-Point Types:** Demangle builtin types like vectors and floating-point types.
- **Outlined Read-Only Object Parsing:** Improved parsing for outlined read-only objects.
- **Protocol and Conformance Descriptor Parsing:** Enhanced parsing for protocol and conformance descriptor runtime records.
- **Nominal Type Descriptor and Opaque Type Descriptor:** Support for nominal and opaque type descriptor runtime records.
- **Advanced Generic Specialization Parsing:** Improved parsing for generic specializations in Swift.
- **Distributed Thunk and Accessible Function Records:** Enhanced parsing for distributed thunk and accessible function runtime records.
- **Macro Expansion Parsing:** Improved parsing for macro expansions in various contexts.

These additions enhance SwiftDemangle's capabilities, making it an indispensable tool for Swift developers.

## Installation

```Swift
# If using Swift Package Manager
dependencies: [
    .package(url: "https://github.com/oozoofrog/SwiftDemangle", .upToNextMajor(from: "5.9.1"))
]
```

## Usage

```Swift
import SwiftDemangle

// Example 1: Demangling a Builtin Vector Type
let mangledVector = "_TtBv4Bf16_"
let demangledVector = SwiftDemangle.demangle(mangledVector)
print(demangledVector)  // Output: Builtin.Vec4xFPIEEE16

// Example 2: Demangling a Protocol Descriptor
let mangledProtocol = "$ss6SimpleHr"
let demangledProtocol = SwiftDemangle.demangle(mangledProtocol)
print(demangledProtocol)  // Output: protocol descriptor runtime record for Swift.Simple
```

## Contributing

Contributions are welcome! If you have ideas for improvements or have found a bug, please feel free to fork the repository, make changes, and submit a pull request.

## License

SwiftDemangle is released under the Apache 2.0 License, ensuring compatibility with the original Swift swift-demangle source code's license terms. For more details, see the LICENSE file in the repository.
