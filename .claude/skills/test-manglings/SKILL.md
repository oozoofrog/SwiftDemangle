---
name: test-manglings
description: Validate mangled symbols against expected demangled output
disable-model-invocation: true
---

# test-manglings

Given a mangled Swift symbol:

1. Check if it exists in `Tests/SwiftDemangleTests/Resources/manglings.txt`
2. Run `swift test --filter testManglings` to verify demangling results
3. Report pass/fail with the expected vs actual demangled output

If a new symbol pair is provided (mangled ---> demangled), add it to the appropriate resource file and run the test to confirm.
