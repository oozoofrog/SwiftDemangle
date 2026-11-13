//
//  OldDemangler.swift
//  Demangling
//
//  Created by spacefrog on 2021/03/29.
//

import Foundation

class OldDemangler: Demanglerable {
    let buffer: [UInt8]
    var position: Int = 0
    
    let numerics: [Character] = (0...9).map(\.description).map(Character.init)
    
    var substitutions: [Node] = []
    
    var printerName: String = ""

    /// Nesting of demangleTypeImpl and demangleContext, the two calls every recursion goes through.
    var depth = 0
    /// Each level costs several kilobytes of stack in a debug build.
    let maxDepth = 64

    required init(_ mangled: String) {
        self.buffer = Self.bytes(of: mangled)
    }
    
    func demangleTopLevel() -> Node? {
        guard nextIf("_T") else { return nil }
        
        let topLevel: Node = Node(kind: .Global)
        
        // First demangle any specialization prefixes.
        if nextIf("TS") {
            repeat {
                if let specAttr = demangleSpecializedAttribute() {
                    topLevel.add(specAttr)
                } else {
                    return nil
                }
                
                // The Substitution header does not share state with the rest
                // of the mangling.
                substitutions.removeAll()
            } while nextIf("_TTS")
            
            // Then check that we have a global.
            guard nextIf("_T") else { return nil }
        } else if nextIf("To") {
            topLevel.add(.ObjCAttribute)
        } else if nextIf("TO") {
            topLevel.add(.NonObjCAttribute)
        } else if nextIf("TD") {
            topLevel.add(.DynamicAttribute)
        } else if nextIf("Td") {
            topLevel.add(.DirectMethodReferenceAttribute)
        } else if nextIf("TV") {
            topLevel.add(.VTableAttribute)
        }
        
        if let global = demangleGlobal() {
            topLevel.add(global)
        } else {
            return nil
        }
        
        // Add a suffix node if there's anything left unmangled.
        if (isNotEmpty) {
            topLevel.add(kind: .Suffix, text: self.text)
        }
        
        guard topLevel.height <= Node.maxDepth else { return nil }
        return topLevel
    }
    
    func demangleDirectness() -> Node.Directness? {
        switch true {
        case nextIf("d"):
            return .direct
        case nextIf("i"):
            return .indirect
        default:
            return nil
        }
    }
    
    func demangleNatural<Number>(number: inout Number) -> Bool where Number: FixedWidthInteger {
        if isEmpty {
            return false
        }
        if let n = nextChar().number(Number.self) {
            number = n
        } else {
            return false
        }
        while true {
            if isEmpty {
                return true
            }
            if let n = peekChar().number(Number.self) {
                number = number &* 10 &+ n
            } else {
                return true
            }
            nextChar()
        }
    }
    
    func demangleBuiltinSize(number: inout UInt64) -> Bool {
        guard demangleNatural(number: &number) else { return false }
        return nextIf("_")
    }
    
    func demangleValueWitnessKind() -> Node.ValueWitnessKind? {
        if isEmpty {
            return nil
        }
        var codes: [Character] = [Character](repeating: "".character, count: 2)
        codes[0] = nextChar()
        if isEmpty {
            return nil
        }
        codes[1] = nextChar()
        let codeStr = codes.map(\.description).joined()
        return Node.ValueWitnessKind(code: codeStr)
    }
    
    func demangleGlobal() -> Node? {
        guard isNotEmpty else { return nil }
        
        // Type metadata.
        if nextIf("M") {
            if nextIf("P") {
                let pattern = Node(kind: .GenericTypeMetadataPattern)
                return demangleChildOrReturn(parent: pattern, kind: .Type)
            }
            if nextIf("a") {
                let accessor = Node(kind: .TypeMetadataAccessFunction)
                return demangleChildOrReturn(parent: accessor, kind: .Type)
            }
            if nextIf("L") {
                let cache = Node(kind: .TypeMetadataLazyCache)
                return demangleChildOrReturn(parent: cache, kind: .Type)
            }
            if nextIf("m") {
                let metaclass = Node(kind: .Metaclass)
                return demangleChildOrReturn(parent: metaclass, kind: .Type)
            }
            if nextIf("n") {
                let nominalType = Node(kind:. NominalTypeDescriptor)
                return demangleChildOrReturn(parent: nominalType, kind: .Type)
            }
            if nextIf("f") {
                let metadata = Node(kind: .FullTypeMetadata)
                return demangleChildOrReturn(parent: metadata, kind: .Type)
            }
            if nextIf("p") {
                let metadata = Node(kind: .ProtocolDescriptor)
                guard let protocolName = demangleProtocolName() else { return nil }
                metadata.add(protocolName)
                return metadata
            }
            
            let metadata = Node(kind: .TypeMetadata)
            return demangleChildOrReturn(parent: metadata, kind: .Type)
        }
        
        // Partial application thunks.
        if nextIf("PA") {
            let kind: Node.Kind
            if nextIf("o") {
                kind = .PartialApplyObjCForwarder
            } else {
                kind = .PartialApplyForwarder
            }
            let forwarder = Node(kind: kind)
            if nextIf("__T") {
                return demangleChildOrReturn(parent: forwarder, kind: .Global)
            }
            return forwarder
        }
        
        // Top-level types, for various consumers.
        if nextIf("t") {
            let type = Node(kind: .TypeMangling)
            return demangleChildOrReturn(parent: type, kind: .Type)
        }
        
        // Value witnesses.
        if nextIf("w") {
            guard let w = demangleValueWitnessKind() else { return nil }
            let witness = Node(kind: .ValueWitness)
            let idx = Node(kind: .Index, payload: .valueWitnessKind(w))
            witness.add(idx)
            return demangleChildOrReturn(parent: witness, kind: .Type)
        }
        
        // Offsets, value witness tables, and protocol witnesses.
        if nextIf("W") {
            if nextIf("V") {
                let witnessTable = Node(kind: .ValueWitnessTable)
                return demangleChildOrReturn(parent: witnessTable, kind: .Type)
            }
            if nextIf("v") {
                let _fieldOffset = Node(kind: .FieldOffset)
                guard let fieldOffset = demangleChildAsNodeOrReturn(parent: _fieldOffset, kind: .Directness) else { return nil }
                if let entity = demangleEntity() {
                    fieldOffset.add(entity)
                } else {
                    return nil
                }
                return fieldOffset
            }
            if nextIf("P") {
                let witnessTable = Node(kind: .ProtocolWitnessTable)
                return demangleChildOrReturn(parent: witnessTable, kind: .ProtocolConformance)
            }
            if nextIf("G") {
                let witnessTable = Node(kind: .GenericProtocolWitnessTable)
                return demangleChildOrReturn(parent: witnessTable, kind: .ProtocolConformance)
            }
            if nextIf("I") {
                let witnessTable = Node(kind: .GenericProtocolWitnessTableInstantiationFunction)
                return demangleChildOrReturn(parent: witnessTable, kind: .ProtocolConformance)
            }
            if nextIf("l") {
                let _accessor = Node(kind: .LazyProtocolWitnessTableAccessor)
                guard let accessor = demangleChildOrReturn(parent: _accessor, kind: .Type) else { return nil }
                return demangleChildOrReturn(parent: accessor, kind: .ProtocolConformance)
            }
            if nextIf("L") {
                let _accessor = Node(kind: .LazyProtocolWitnessTableCacheVariable)
                guard let accessor = demangleChildOrReturn(parent: _accessor, kind: .Type) else { return nil }
                return demangleChildOrReturn(parent: accessor, kind: .ProtocolConformance)
            }
            if nextIf("a") {
                let tableTemplate = Node(kind: .ProtocolWitnessTableAccessor)
                return demangleChildOrReturn(parent: tableTemplate, kind: .ProtocolConformance)
            }
            if nextIf("t") {
                let _accessor = Node(kind: .AssociatedTypeMetadataAccessor)
                guard let accessor = demangleChildOrReturn(parent: _accessor, kind: .ProtocolConformance) else { return nil }
                if let child = demangleDeclName() {
                    accessor.add(child)
                } else {
                    return nil
                }
                return accessor
            }
            if nextIf("T") {
                let _accessor = Node(kind: .AssociatedTypeWitnessTableAccessor)
                guard let accessor = demangleChildOrReturn(parent: _accessor, kind: .ProtocolConformance) else { return nil }
                if let child = demangleDeclName() {
                    accessor.add(child)
                } else {
                    return nil
                }
                if let child = demangleProtocolName() {
                    accessor.add(child)
                } else {
                    return nil
                }
                return accessor
            }
            return nil
        }
        
        // Other thunks.
        if nextIf("T") {
            if nextIf("R") {
                var thunk = Node(kind: .ReabstractionThunkHelper)
                guard demangleReabstractSignature(signature: &thunk) else { return nil }
                return thunk
            }
            if nextIf("r") {
                var thunk = Node(kind: .ReabstractionThunk)
                guard demangleReabstractSignature(signature: &thunk) else { return nil }
                return thunk
            }
            if nextIf("W") {
                let _thunk = Node(kind: .ProtocolWitness)
                guard let thunk = demangleChildOrReturn(parent: _thunk, kind: .ProtocolConformance) else { return nil }
                // The entity is mangled in its own generic context.
                guard let entity = demangleEntity() else { return nil }
                thunk.add(entity)
                return thunk
            }
            return nil
        }
        return demangleEntity()
    }
}
