//
//  OldDemangler+Identifiers.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    func demangleIdentifier(kind _kind: Node.Kind? = nil) -> Node? {
        if isEmpty {
            return nil
        }
        
        let isPunycoded = nextIf("X")
        
        func decode(_ text: String) -> String {
            guard isPunycoded else { return text }
            return Punycode(string: text).decode() ?? ""
        }
        
        var _kind = _kind
        
        var isOperator = false
        if nextIf("o") {
            isOperator = true
            // Operator identifiers aren't valid in the contexts that are
            // building more specific identifiers.
            guard _kind == nil else { return nil }
            
            let op_mode = nextChar()
            switch op_mode {
            case "p":
                _kind = .PrefixOperator
            case "P":
                _kind = .PostfixOperator
            case "i":
                _kind = .InfixOperator
            default:
                return nil
            }
        }
        
        let kind: Node.Kind = _kind ?? .Identifier
        
        var length: UInt64 = 0
        guard demangleNatural(number: &length) else { return nil }
        guard hasAtLeast(length) else { return nil }
        
        var identifier = slice(Int(length))
        advanceOffset(Int(length))
        
        // Decode Unicode identifiers.
        identifier = decode(identifier)
        if identifier.isEmpty {
            return nil
        }
        
        // Decode operator names.
        var opDecodeBuffer: String = ""
        if isOperator {
            // abcdefghijklmnopqrstuvwxyz
            let op_char_table: [Character] = "& @/= >    <*!|+?%-~   ^ .".map({$0})
            for c in identifier {
                guard let asciiValue = c.asciiValue else {
                    opDecodeBuffer.append(c)
                    continue
                }
                
                guard c >= "a", c <= "z" else { return nil }
                let o = op_char_table[Int(asciiValue - "a".first!.asciiValue!)]
                guard o != " " else { return nil }
                opDecodeBuffer.append(o)
            }
            identifier = opDecodeBuffer
        }
        
        return Node(kind: kind, text: identifier)
    }
    
    func demangleIndex(_ number: inout UInt64) -> Bool {
        if nextIf("_") {
            number = 0
            return true
        }
        if demangleNatural(number: &number) {
            if !nextIf("_") {
                return false
            }
            number &+= 1
            return true
        } else {
            return false
        }
    }
    
    /// Demangle an <index> and package it as a node of some kind.
    func demangleIndexAsNode(kind: Node.Kind = .Number) -> Node? {
        var index: UInt64 = 0
        guard demangleIndex(&index) else { return nil }
        return Node(kind: kind, index: index)
    }

    func createSwiftType(typeKind: Node.Kind, name: String) -> Node {
        let type = Node(kind: typeKind)
        type.add(Node(kind: .Module, text: .STDLIB_NAME))
        type.add(Node(kind: .Identifier, text: name))
        return type
    }
    
    func demangleSubstitutionIndex() -> Node? {
        if isEmpty {
            return nil
        }
        if nextIf("o") {
            return .init(kind: .Module, text: .MANGLING_MODULE_OBJC)
        }
        if nextIf("C") {
            return .init(kind: .Module, text: .MANGLING_MODULE_CLANG_IMPORTER)
        }
        if nextIf("a") {
          return createSwiftType(typeKind: .Structure, name: "Array")
        }
        if nextIf("b") {
          return createSwiftType(typeKind: .Structure, name: "Bool")
        }
        if nextIf("c") {
          return createSwiftType(typeKind: .Structure, name: "UnicodeScalar")
        }
        if nextIf("d") {
          return createSwiftType(typeKind: .Structure, name: "Double")
        }
        if nextIf("f") {
          return createSwiftType(typeKind: .Structure, name: "Float")
        }
        if nextIf("i") {
          return createSwiftType(typeKind: .Structure, name: "Int")
        }
        if nextIf("V") {
          return createSwiftType(typeKind: .Structure, name: "UnsafeRawPointer")
        }
        if nextIf("v") {
          return createSwiftType(typeKind: .Structure, name: "UnsafeMutableRawPointer")
        }
        if nextIf("P") {
          return createSwiftType(typeKind: .Structure, name: "UnsafePointer")
        }
        if nextIf("p") {
          return createSwiftType(typeKind: .Structure, name: "UnsafeMutablePointer")
        }
        if nextIf("q") {
          return createSwiftType(typeKind: .Enum, name: "Optional")
        }
        if nextIf("Q") {
          return createSwiftType(typeKind: .Enum, name: "ImplicitlyUnwrappedOptional")
        }
        if nextIf("R") {
          return createSwiftType(typeKind: .Structure, name: "UnsafeBufferPointer")
        }
        if nextIf("r") {
          return createSwiftType(typeKind: .Structure, name: "UnsafeMutableBufferPointer")
        }
        if nextIf("S") {
          return createSwiftType(typeKind: .Structure, name: "String")
        }
        if nextIf("u") {
          return createSwiftType(typeKind: .Structure, name: "UInt")
        }
        var index_sub: UInt64 = 0
        guard demangleIndex(&index_sub) else { return nil }
        guard index_sub < substitutions.count else { return nil }
        // Reusing a deep node is the one way to grow the tree without recursing.
        guard substitutions[Int(index_sub)].height < Node.maxDepth else { return nil }
        return substitutions[Int(index_sub)]
    }
}
