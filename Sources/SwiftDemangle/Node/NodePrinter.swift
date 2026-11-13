//
//  NodePrinter.swift
//  Demangling
//
//  Created by spacefrog on 2021/03/30.
//

import Foundation

public enum PrintingError: String, Error {
    case shouldBeHandleInPrintSpecializationPrefix
    case unexpectedCaseNonDifferentiable
}

struct NodePrinter {
    
    var options: DemangleOptions
    var printText: String = ""
    private(set) var isValid: Bool = true
    var isSpecializationPrefixPrinted = false
    
    let depthLimit = Node.maxDepth
    
    /// How many symbols deep this printer sits inside a symbol being printed.
    private let nesting: Int
    /// A constant-propagated symbol nested deeper than this is printed as its mangled text.
    private static let nestingLimit = 8
    
    init(options: DemangleOptions, nesting: Int = 0) {
        self.options = options
        self.nesting = nesting
    }
    
    /// Demangles a symbol that appears as text inside the symbol being printed.
    func demangleNested(_ text: String) throws -> String {
        guard nesting < Self.nestingLimit else { return text }
        return try text.demangleSymbolAsString(with: .nestedSymbolOptions, nesting: nesting + 1)
    }
    
    mutating func setInvalid() {
        isValid = false
    }
    
    mutating func printer(_ text: String) {
        printText.append(text)
    }
    
    mutating func printerText(_ node: Node) {
        printer(node.text)
    }
    
    mutating func printerIndex(_ index: Int) {
        printer(index.description)
    }
    
    mutating func printerHex(_ index: UInt64?) {
        printer(String(format: "%lld", index ?? 0))
    }
    
    mutating func printRoot(_ node: Node) throws -> String {
        try printNode(node, depth: 0)
        return printText
    }
}

extension NodePrinter {
    
    enum TypePrinting {
        case noType, withColon, functionStyle
    }
    
    func nodeToString(root: Node?) -> String {
        guard let root else {
            return ""
        }
        var printer = NodePrinter(options: self.options)
        do {
            return try printer.printRoot(root)
        } catch {
            return ""
        }
    }
}
