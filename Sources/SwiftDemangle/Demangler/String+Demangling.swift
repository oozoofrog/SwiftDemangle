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
    
    func demangling(_ options: DemangleOptions, printDebugInformation: Bool = false) throws -> String {
        var mangled = self
        if mangled.hasPrefix("S") || mangled.hasPrefix("s") {
            mangled = "$" + mangled
        }
        guard let regex = try? NSRegularExpression(pattern: "[^ \n\r\t<>;:]+", options: []) else {
            return self
        }
        return try regex.matches(in: mangled, options: [], range: NSRange(mangled.startIndex..<mangled.endIndex, in: mangled)).reversed().reduce(mangled, { (text, match) -> String in
            if let range = Range<String.Index>.init(match.range, in: text) {
                let demangled = try text[range].demangleSymbolAsString(with: options, printDebugInformation: printDebugInformation)
                return text.replacingCharacters(in: range, with: demangled)
            } else {
                return text
            }
        })
    }
    
    /// The demangled syntax tree, available for read-only traversal.
    /// Returns `nil` if this string cannot be demangled as a symbol.
    var node: Node? {
        demangleSymbolAsNode(printDebugInformation: false)
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
