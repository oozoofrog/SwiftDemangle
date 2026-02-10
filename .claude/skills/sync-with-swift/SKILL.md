---
name: sync-with-swift
description: Guide for syncing with upstream Swift compiler demangling changes
---

# sync-with-swift

This project is a pure Swift port of the Swift compiler's `swift-demangle`. When syncing with a new Swift version:

## Checklist

1. **Node.Kind**: Check for new enum cases in `Node.swift` `Kind` enum
2. **Demangler**: Check for new operators in `demangleOperator()` in `Demangler.swift`
3. **NodePrinter**: Add corresponding print rules in `printNode()` in `NodePrinter.swift`
4. **DemangleOptions**: Check for new options in `DemangleOptions.swift`
5. **Test data**: Update `Tests/SwiftDemangleTests/Resources/manglings.txt` with new test cases

## Reference

- Upstream source: https://github.com/swiftlang/swift/tree/main/lib/Demangling
- Diff guide: `Diff.md` in project root tracks differences from upstream
