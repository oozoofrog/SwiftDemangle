//
//  NodePrinter+Helpers.swift
//  Demangling
//

import Foundation

extension NodePrinter {
    
    mutating func printChildren(nodes: [Node], depth: Int, separator: String? = nil) throws {
        for (offset, node) in nodes.enumerated() {
            try printNode(node, depth: depth + 1)
            if let separator, offset < nodes.count - 1 {
                printer(separator)
            }
        }
    }
    
    mutating func printChildren(_ node: Node, depth: Int, separator: String? = nil) throws {
        try printChildren(nodes: node.copyOfChildren, depth: depth, separator: separator)
    }
    
    mutating func printWithParens(_ type: Node, depth: Int) throws {
        let needsParens = !type.isSimpleType
        if needsParens {
            printer("(")
        }
        try printNode(type, depth: depth + 1)
        if needsParens {
            printer(")")
        }
    }
    
    func findSugar(_ node: Node) -> SugarType {
        if node.numberOfChildren == 1, node.kind == .Type {
            return findSugar(node.children(0))
        }
        
        if node.numberOfChildren != 2 {
            return .none
        }
        
        if node.kind != .BoundGenericEnum, node.kind != .BoundGenericStructure {
            return .none
        }
        
        let unboundType = node.children(0).children(0) // drill through Type
        let typeArgs = node.children(1)
        
        if node.kind == .BoundGenericEnum {
            // Swift.Optional
            if unboundType.children(1).isIdentifier(desired: "Optional"),
               typeArgs.numberOfChildren == 1,
               unboundType.children(0).isSwiftModule {
                return .optional
            }
            
            // Swift.ImplicitlyUnwrappedOptional
            if unboundType.children(1).isIdentifier(desired: "ImplicitlyUnwrappedOptional"),
               typeArgs.numberOfChildren == 1,
               unboundType.children(0).isSwiftModule {
                return .implicitlyUnwrappedOptional
            }
            
            return .none
        }
        
        assert(node.kind == .BoundGenericStructure)
        
        // Array
        if unboundType.children(1).isIdentifier(desired: "Array"),
           typeArgs.numberOfChildren == 1,
           unboundType.children(0).isSwiftModule {
            return .array
        }
        
        // Dictionary
        if unboundType.children(1).isIdentifier(desired: "Dictionary"),
           typeArgs.numberOfChildren == 2,
           unboundType.children(0).isSwiftModule {
            return .dictionary
        }
        
        return .none
    }
    
    mutating func printOptionalIndex(_ node: Node) {
        assert(node.kind == .Index || node.kind == .UnknownIndex)
        if let index = node.index {
            printer("#" + index.description + " ")
        }
    }
    
    func quoted(text: String) -> String {
        var temp = "\""
        for character in text {
            switch character {
            case "\\":
                temp.append("\\\\")
            case "\t":
                temp.append("\\t")
            case "\n":
                temp.append("\\n")
            case "\r":
                temp.append("\\r")
            case "\"":
                temp.append("\\\"")
            case .zero:
                temp.append("\\0")
            default:
                if character < Character(UnicodeScalar(0x20)) || character >= Character(UnicodeScalar(0x7f)) {
                    temp.append("\\x")
                    for scalar in character.unicodeScalars.map(\.utf16).flatMap({ $0 }) {
                        temp.append(String(scalar, radix: 16, uppercase: true))
                    }
                } else {
                    temp.append(character)
                }
            }
        }
        
        temp.append("\"")
        return temp
    }
}
