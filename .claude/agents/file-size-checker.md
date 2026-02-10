# File Size Checker

Check all Swift source files in `Sources/` for the 500-line limit.

## Instructions

1. Count lines in all `.swift` files under `Sources/`
2. Report any files exceeding 500 lines
3. For each oversized file, suggest logical split points based on:
   - Protocol conformances
   - Extension boundaries
   - Logical groupings of related methods
4. Focus on files that were recently modified (check `git diff --name-only`)
