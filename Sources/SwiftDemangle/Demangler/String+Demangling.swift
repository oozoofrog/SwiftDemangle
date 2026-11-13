//
//  String+Demangling.swift
//  SwiftDemangle
//
//  Created by spacefrog on 2021/06/27.
//

import Foundation

public extension String {
    
    var demangled: String {
        guard let demangled = try? self.demangling(.defaultOptions) else { return self }
        return demangled
    }
    
    @available(*, deprecated, message: "printDebugInformation has no effect; use demangling(_:)")
    func demangling(_ options: DemangleOptions, printDebugInformation: Bool) throws -> String {
        try demangling(options)
    }
    
    /// Replaces every symbol in this string with its demangled form.
    ///
    /// A string that starts with `s` or `S` is also tried as a symbol without its `$`
    /// prefix; the `$` is added only when that makes the leading token demangle.
    func demangling(_ options: DemangleOptions) throws -> String {
        if hasPrefix("S") || hasPrefix("s") {
            let prefixed = "$" + self
            let leadingToken = String(prefixed.unicodeScalars.prefix(while: { !Self.symbolSeparators.contains($0) }))
            if Self.isDemangleable(leadingToken) {
                return try prefixed.replacingSymbols(options)
            }
        }
        return try replacingSymbols(options)
    }
    
    /// Characters that end a symbol inside a longer text; the complement of `symbolPattern`.
    private static let symbolSeparators: Set<Unicode.Scalar> = [" ", "\n", "\r", "\t", "<", ">", ";", ":"]
    
    private static func isDemangleable(_ symbol: String) -> Bool {
        guard let root = symbol.demangleSymbolAsNode() else { return false }
        var printer = NodePrinter(options: .defaultOptions)
        return (try? printer.printRoot(root))?.isEmpty == false
    }
    
    /// A run of characters that may form a symbol.
    private static let symbolPattern = try? NSRegularExpression(pattern: "[^ \n\r\t<>;:]+", options: [])
    
    private func replacingSymbols(_ options: DemangleOptions) throws -> String {
        guard let regex = Self.symbolPattern else {
            return self
        }
        return try regex.matches(in: self, options: [], range: NSRange(startIndex..<endIndex, in: self)).reversed().reduce(self, { (text, match) -> String in
            if let range = Range<String.Index>.init(match.range, in: text) {
                let demangled = try text[range].demangleSymbolAsString(with: options)
                return text.replacingCharacters(in: range, with: demangled)
            } else {
                return text
            }
        })
    }
    
    /// The demangled syntax tree, available for read-only traversal.
    /// Returns `nil` if this string cannot be demangled as a symbol.
    var node: Node? {
        demangleSymbolAsNode()
    }

    /// The innermost nominal type that owns this symbol.
    ///
    /// Nominal type symbols return their own declaration node. Members, accessors,
    /// and local declarations follow their declaration context; extension members
    /// return the extended type. Bound generic types return the nominal declaration
    /// rather than one of their generic arguments.
    ///
    /// Returns `nil` for module-level declarations, invalid symbols, unresolved
    /// symbolic references, and unsupported or ambiguous wrappers (including
    /// protocol witness and vtable thunks). Parameter types, return types, and
    /// conformance types are never searched as a fallback.
    var nominalOwner: Node? {
        node?.extractNominalOwner()
    }

    var symbolKind: Node.Kind? {
        node?.extractSymbolKind()
    }
}
