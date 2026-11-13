//
//  OldDemangler+GenericSignatures.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    func getDependentGenericParamType(depth: UInt64, index: UInt64) -> Node? {
        self.printerName = NodePrinter(options: .defaultOptions).genericParameterName(depth: depth, index: index)
        let paramTy = Node(kind: .DependentGenericParamType)
        paramTy.add(kind: .Index, payload: .index(depth))
        paramTy.add(kind: .Index, payload: .index(index))
        return paramTy
    }
    
    func demangleGenericParamIndex() -> Node? {
        var depth: UInt64 = 0, index: UInt64 = 0
        
        if nextIf("d") {
            guard demangleIndex(&depth) else { return nil }
            depth &+= 1
            guard demangleIndex(&index) else { return nil }
        } else if nextIf("x") {
            depth = 0
            index = 0
        } else {
            guard demangleIndex(&index) else { return nil }
            depth = 0
            index &+= 1
        }
        return getDependentGenericParamType(depth: depth, index: index)
    }
    
    func demangleDependentMemberTypeName(base: Node) -> Node? {
        assert(base.kind == .Type, "base should be a type")
        var assocTy: Node?
        
        if nextIf("S") {
            assocTy = demangleSubstitutionIndex()
            if assocTy == nil {
                return nil
            }
            if assocTy?.kind != .DependentAssociatedTypeRef {
                return nil
            }
        } else {
            var protocolNode: Node?
            if nextIf("P") {
                protocolNode = demangleProtocolName()
                if protocolNode == nil {
                    return nil
                }
            }
            
            // TODO: If the protocol name was elided from the assoc type mangling,
            // we could try to fish it out of the generic signature constraints on the
            // base.
            guard let id = demangleIdentifier() else { return nil }
            assocTy = Node(kind: .DependentAssociatedTypeRef)
            if assocTy == nil {
                return nil
            }
            assocTy?.add(id)
            if let protocolNode = protocolNode {
                assocTy?.add(protocolNode)
            }
            
            if let assocTy = assocTy {
                substitutions.append(assocTy)
            }
        }
        
        let depTy = Node(kind: .DependentMemberType)
        depTy.add(base)
        if let assocTy = assocTy {
            depTy.add(assocTy)
        }
        return depTy
    }
    
    func demangleAssociatedTypeSimple() -> Node? {
        // Demangle the base type.
        guard let base = demangleGenericParamIndex() else { return nil }
        
        // Demangle the associated type name.
        let type = Node(kind: .Type)
        type.add(base)
        return demangleDependentMemberTypeName(base: type)
    }
    
    func demangleAssociatedTypeCompound() -> Node? {
        // Demangle the base type.
        var base = demangleGenericParamIndex()
        guard base.hasValue else { return nil }
        
        // Demangle the associated type chain.
        while !nextIf("_") {
            let nodeType = Node(kind: .Type)
            nodeType.add(base)
            
            base = demangleDependentMemberTypeName(base: nodeType)
            guard base.hasValue else { return nil }
        }
        
        return base
    }
    
    func demangleDependentType() -> Node? {
        guard isNotEmpty else { return nil }

        // A dependent member type begins with a non-index, non-'d' character.
        let c = peekChar()
        if c != "d", c != "_", !c.isNumber {
            guard let baseType = demangleType() else { return nil }
            return demangleDependentMemberTypeName(base: baseType)
        }
      
      // Otherwise, we have a generic parameter.
      return demangleGenericParamIndex()
    }
    
    func demangleConstrainedTypeImpl() -> Node? {
        // The constrained type can only be a generic parameter or an associated
        // type thereof. The 'q' introducer is thus left off of generic params.
        if nextIf("w") {
            return demangleAssociatedTypeSimple()
        }
        if nextIf("W") {
            return demangleAssociatedTypeCompound()
        }
        return demangleGenericParamIndex()
    }
    
    func demangleConstrainedType() -> Node? {
        guard let type = demangleConstrainedTypeImpl() else { return nil }
        let constrainedType = Node(kind: .Type)
        constrainedType.add(type)
        return constrainedType
    }
    
    func demangleGenericSignature(isPseudogeneric: Bool = false) -> Node? {
        let sig = Node(kind: isPseudogeneric ? .DependentPseudogenericSignature : .DependentGenericSignature)
        // First read in the parameter counts at each depth.
        var count = UInt64.max
        
        func addCount(sig: Node, count: UInt64) {
            sig.add(.init(kind: .DependentGenericParamCount, payload: .index(count)))
        }
        
        while peekChar() != "R", peekChar() != "r" {
            if nextIf("z") {
                count = 0
            } else if demangleIndex(&count) {
                count &+= 1
            } else {
                return nil
            }
            addCount(sig: sig, count: count)
        }
        
        // No mangled parameters means we have exactly one.
        if count == .max {
            count = 1
            addCount(sig: sig, count: count)
        }
        
        // Next read in the generic requirements, if any.
        if nextIf("r") {
            return sig
        }
        
        if !nextIf("R") {
            return nil
        }
        
        while !nextIf("r") {
            guard let reqt = demangleGenericRequirement() else { return nil }
            sig.add(reqt)
        }
        
        return sig
    }
    
    func demangleMetatypeRepresentation() -> Node? {
        if nextIf("t") {
            return Node(kind: .MetatypeRepresentation, text: "@thin")
        }

        if nextIf("T") {
            return Node(kind: .MetatypeRepresentation, text: "@thick")
        }

        if nextIf("o") {
            return Node(kind: .MetatypeRepresentation, text: "@objc_metatype")
        }

        // Unknown metatype representation
        return nil
    }
    
    func demangleGenericRequirement() -> Node? {
        guard let constrainedType = demangleConstrainedType() else { return nil }
        if nextIf("z") {
            guard let second = demangleType() else { return nil }
            let reqt = Node(kind: .DependentGenericSameTypeRequirement)
            reqt.add(constrainedType)
            reqt.add(second)
            return reqt
        }
        
        if nextIf("l") {
            let name: String
            let kind: Node.Kind
            var size = UInt64.max
            var alignment = UInt64.max
            if nextIf("U") {
                kind = .Identifier
                name = "U"
            } else if nextIf("R") {
                kind = .Identifier
                name = "R"
            } else if nextIf("N") {
                kind = .Identifier
                name = "N"
            } else if nextIf("T") {
                kind = .Identifier
                name = "T"
            } else if nextIf("E") {
                kind = .Identifier
                guard demangleNatural(number: &size) else { return nil }
                guard nextIf("_") else { return nil }
                guard demangleNatural(number: &alignment) else { return nil }
                name = "E"
            } else if nextIf("e") {
                kind = .Identifier
                guard demangleNatural(number: &size) else { return nil }
                name = "e"
            } else if nextIf("M") {
                kind = .Identifier
                guard demangleNatural(number: &size) else { return nil }
                guard nextIf("_") else { return nil }
                guard demangleNatural(number: &alignment) else { return nil }
                name = "M"
            } else if nextIf("m") {
                kind = .Identifier
                guard demangleNatural(number: &size) else { return nil }
                name = "m"
            } else {
                return nil
            }
            
            let second = Node(kind: kind, text: name)
            let reqt = Node(kind: .DependentGenericLayoutRequirement)
            reqt.add(constrainedType)
            reqt.add(second)
            if size != .max {
                reqt.add(kind: .Number, payload: .index(size))
                if alignment != .max {
                    reqt.add(kind: .Number, payload: .index(alignment))
                }
            }
            return reqt
        }
        
        // Base class constraints are introduced by a class type mangling, which
        // will begin with either 'C' or 'S'.
        guard isNotEmpty else { return nil }
        
        var constraint: Node?
        
        let next = peekChar()
        
        if next == "C" {
            constraint = demangleType()
            guard constraint.hasValue else { return nil }
        } else if (next == "S") {
            // A substitution may be either the module name of a protocol or a full
            // type name.
            var typeName: Node?
            nextChar()
            guard let sub = demangleSubstitutionIndex() else { return nil }
            if sub.kind == .Protocol || sub.kind == .Class {
                typeName = sub
            } else if (sub.kind == .Module) {
                typeName = demangleProtocolNameGivenContext(sub)
                guard typeName.hasValue else { return nil }
            } else {
                return nil
            }
            constraint = Node(kind: .Type)
            constraint?.add(typeName)
        } else {
            constraint = demangleProtocolName()
            guard constraint.hasValue else { return nil }
        }
        
        let reqt = Node(kind: .DependentGenericConformanceRequirement)
        reqt.add(constrainedType)
        reqt.add(constraint)
        return reqt
    }
    
    func demangleArchetypeType() -> Node? {
        func makeAssociatedType(_ root: Node) -> Node? {
            guard let name = demangleIdentifier() else { return nil }
            let assocType = Node(kind: .AssociatedTypeRef)
            assocType.add(root)
            assocType.add(name)
            substitutions.append(assocType)
            return assocType
        }
        
        if nextIf("Q") {
            guard let root = demangleArchetypeType() else { return nil }
            return makeAssociatedType(root)
        }
        if nextIf("S") {
            guard let sub = demangleSubstitutionIndex() else { return nil }
            return makeAssociatedType(sub)
        }
        if nextIf("s") {
            return makeAssociatedType(.init(kind: .Module, text: .STDLIB_NAME))
        }
        return nil
    }
}
