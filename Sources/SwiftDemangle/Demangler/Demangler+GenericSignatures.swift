//
//  Demangler+GenericSignatures.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleGenericSignature(_ hasParamCounts: Bool) -> Node? {
        let Sig = createNode(.DependentGenericSignature)
        if hasParamCounts {
            while !nextIf("l") {
                var count = 0
                if !nextIf("z") {
                    count = demangleIndex() + 1
                }
                if count < 0 {
                    return nil
                }
                Sig.addChild(createNode(.DependentGenericParamCount, count))
            }
        } else {
            Sig.addChild(createNode(.DependentGenericParamCount, 1))
        }
        let NumCounts = Sig.getNumChildren()
        while let Req = popNode(isRequirement) {
            Sig.addChild(Req)
        }
        Sig.reverseChildren(NumCounts)
        return Sig
    }
    
    enum TypeKind {
        case Generic
        case Assoc
        case CompoundAssoc
        case Substitution
    }
    enum ConstraintKind {
        case `Protocol`
        case BaseClass
        case SameType
        case SameShape
        case Layout
        case PackMarker
        case Inverse
        case ValueMarker
    }
    
    func demangleGenericRequirement() -> Node? {
        
        let TypeKind: TypeKind
        let ConstraintKind: ConstraintKind
        
        var inverseKind: Node?
        switch (nextChar()) {
        case "V":
            ConstraintKind = .ValueMarker
            TypeKind = .Generic
        case "v":
            ConstraintKind = .PackMarker
            TypeKind = .Generic
            break
        case "C": 
            ConstraintKind = .BaseClass
            TypeKind = .CompoundAssoc
        case "c":
            ConstraintKind = .BaseClass
            TypeKind = .Assoc
        case "b":
            ConstraintKind = .BaseClass
            TypeKind = .Generic
        case "B":
            ConstraintKind = .BaseClass
            TypeKind = .Substitution
        case "t":
            ConstraintKind = .SameType
            TypeKind = .Assoc
        case "T":
            ConstraintKind = .SameType
            TypeKind = .CompoundAssoc
        case "s":
            ConstraintKind = .SameType
            TypeKind = .Generic
        case "S":
            ConstraintKind = .SameType
            TypeKind = .Substitution
        case "m":
            ConstraintKind = .Layout
            TypeKind = .Assoc
        case "M":
            ConstraintKind = .Layout
            TypeKind = .CompoundAssoc
        case "l":
            ConstraintKind = .Layout
            TypeKind = .Generic
        case "L":
            ConstraintKind = .Layout
            TypeKind = .Substitution
        case "p":
            ConstraintKind = .Protocol
            TypeKind = .Assoc
        case "P":
            ConstraintKind = .Protocol
            TypeKind = .CompoundAssoc
        case "Q":
            ConstraintKind = .Protocol
            TypeKind = .Substitution
        case "h":
            ConstraintKind = .SameShape
            TypeKind = .Generic
        case "i":
            ConstraintKind = .Inverse
            TypeKind = .Generic
            inverseKind = demangleIndexAsNode()
            if inverseKind == nil {
                return nil
            }
        case "j":
            ConstraintKind = .Inverse
            TypeKind = .Assoc
            inverseKind = demangleIndexAsNode()
            if inverseKind == nil {
                return nil
            }
        case "J":
            ConstraintKind = .Inverse
            TypeKind = .CompoundAssoc
            inverseKind = demangleIndexAsNode()
            if inverseKind == nil {
                return nil
            }
        case "I":
            ConstraintKind = .Inverse
            TypeKind = .Substitution
            inverseKind = demangleIndexAsNode()
            if inverseKind == nil {
                return nil
            }
            break
        default:
            ConstraintKind = .Protocol
            TypeKind = .Generic
            pushBack()
            break
        }
        
        let ConstrTy: Node?
        
        switch TypeKind {
        case .Generic:
            ConstrTy = createType(demangleGenericParamIndex())
        case .Assoc:
            ConstrTy = demangleAssociatedTypeSimple(demangleGenericParamIndex())
            addSubstitution(ConstrTy)
        case .CompoundAssoc:
            ConstrTy = demangleAssociatedTypeCompound(demangleGenericParamIndex())
            addSubstitution(ConstrTy)
        case .Substitution:
            ConstrTy = popNode(.Type)
        }
        
        switch ConstraintKind {
        case .ValueMarker:
            return createWithChildren(.DependentGenericParamValueMarker, ConstrTy, popNode(.Type))
        case .PackMarker:
            return createWithChildren(.DependentGenericParamPackMarker, ConstrTy)
        case .Protocol:
            return createWithChildren(.DependentGenericConformanceRequirement, ConstrTy, popProtocol())
        case .Inverse:
            return createWithChildren(.DependentGenericInverseConformanceRequirement, ConstrTy, inverseKind)
        case .BaseClass:
            return createWithChildren(.DependentGenericConformanceRequirement, ConstrTy, popNode(.Type))
        case .SameType:
            return createWithChildren(.DependentGenericSameTypeRequirement, ConstrTy, popNode(.Type))
        case .SameShape:
            return createWithChildren(.DependentGenericSameShapeRequirement, ConstrTy, popNode(.Type))
        case .Layout:
            let c = nextChar()
            var size: Node?
            var alignment: Node?
            var name: String
            if c == "U" {
                name = "U"
            } else if c == "R" {
                name = "R"
            } else if c == "N" {
                name = "N"
            } else if c == "C" {
                name = "C"
            } else if c == "D" {
                name = "D"
            } else if c == "T" {
                name = "T"
            } else if c == "B" {
                name = "B"
            } else if c == "E" {
                size = demangleIndexAsNode()
                if size == nil {
                    return nil
                }
                alignment = demangleIndexAsNode()
                name = "E"
            } else if c == "e" {
                size = demangleIndexAsNode()
                if size == nil {
                    return nil
                }
                name = "e"
            } else if c == "M" {
                size = demangleIndexAsNode()
                if size == nil {
                    return nil
                }
                alignment = demangleIndexAsNode()
                name = "M"
            } else if c == "m" {
                size = demangleIndexAsNode()
                if size == nil {
                    return nil
                }
                name = "m"
            } else if c == "S" {
                size = demangleIndexAsNode()
                if size == nil {
                    return nil
                }
                name = "S"
            } else {
                // Unknown layout constraint.
                return nil
            }
            
            let NameNode = createNode(.Identifier, name)
            let LayoutRequirement = createWithChildren(.DependentGenericLayoutRequirement, ConstrTy, NameNode)
            if let size {
                addChild(LayoutRequirement, size)
            }
            if let alignment {
                addChild(LayoutRequirement, alignment)
            }
            return LayoutRequirement
            
        }
    }
    
    func demangleGenericType() -> Node? {
        let GenSig = popNode(.DependentGenericSignature)
        let Ty = popNode(.Type)
        return createType(createWithChildren(.DependentGenericType, GenSig, Ty))
    }
}
