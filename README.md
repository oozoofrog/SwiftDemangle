# SwiftDemangle

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Foozoofrog%2FSwiftDemangle%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/oozoofrog/SwiftDemangle)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Foozoofrog%2FSwiftDemangle%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/oozoofrog/SwiftDemangle)

demangler for mangled symbol that translated from [swift-demangle](https://github.com/apple/swift/blob/main/tools/swift-demangle/swift-demangle.cpp) [Swift 5.5](https://github.com/apple/swift/tree/release/5.5)

## Installation
**SwiftDemangle** supply **SPM** only
```swift
dependencies: [
  .package(url: "https://github.com/oozoofrog/SwiftDemangle", from: "5.5.8"),
],
```

## Usage

```Swift
import SwiftDemangle

print("_TFCs13_NSSwiftArray29canStoreElementsOfDynamicTypefPMP_Sb".demangled)
```
