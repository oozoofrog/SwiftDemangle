//
//  Node+TypeClassification.swift
//  Demangling
//

import Foundation

extension Node {
    var isExistentialType: Bool {
        [Kind.ExistentialMetatype, .ProtocolList, .ProtocolListWithClass, .ProtocolListWithAnyObject].contains(kind)
    }
    
    var isClassType: Bool { kind == .Class }
    
    var isAlias: Bool {
        switch self.kind {
        case .Type:
            return firstChild.isAlias
        case .TypeAlias:
            return true
        default:
            return false
        }
    }
    
    var isClass: Bool {
        switch self.kind {
        case .Type:
            return firstChild.isClass
        case .Class, .BoundGenericClass:
            return true
        default:
            return false
        }
    }
    
    var isEnum: Bool {
        switch self.kind {
        case .Type:
            return firstChild.isEnum
        case .Enum, .BoundGenericEnum:
            return true
        default:
            return false
        }
    }
    
    var isProtocol: Bool {
        switch self.kind {
        case .Type:
            return firstChild.isProtocol
        case .Protocol, .ProtocolSymbolicReference, .ObjectiveCProtocolSymbolicReference:
            return true
        default:
            return false
        }
    }
    
    var isStruct: Bool {
        switch self.kind {
        case .Type:
            return firstChild.isStruct
        case .Structure, .BoundGenericStructure:
            return true
        default:
            return false
        }
    }
    
    var isConsumesGenericArgs: Bool {
        switch kind {
        case .Variable,
                .Subscript,
                .ImplicitClosure,
                .ExplicitClosure,
                .DefaultArgumentInitializer,
                .Initializer,
                .PropertyWrapperBackingInitializer,
                .PropertyWrappedFieldInitAccessor,
                .PropertyWrapperInitFromProjectedValue:
            return false
        default:
            return true
        }
    }
    
    var isSpecialized: Bool {
        switch kind {
        case .BoundGenericStructure,.BoundGenericEnum,.BoundGenericClass,.BoundGenericOtherNominalType,.BoundGenericTypeAlias,.BoundGenericProtocol,.BoundGenericFunction:
            return true
        case .Structure, .Enum, .Class, .TypeAlias, .OtherNominalType, .Protocol, .Function, .Allocator, .Constructor, .Destructor, .Variable, .Subscript, .ExplicitClosure, .ImplicitClosure, .Initializer, .PropertyWrapperBackingInitializer, .PropertyWrapperInitFromProjectedValue, .DefaultArgumentInitializer, .Getter, .Setter, .WillSet, .DidSet, .ReadAccessor, .ModifyAccessor, .UnsafeAddressor, .UnsafeMutableAddressor:
            return firstChild.isSpecialized
        case .Extension:
            return children(1).isSpecialized
        default:
            return false
        }
    }
    
    func unspecialized() -> Node? {
        var NumToCopy = 2
        switch kind {
        case .Function, .Getter, .Setter, .WillSet, .DidSet, .ReadAccessor, .ModifyAccessor, .UnsafeAddressor, .UnsafeMutableAddressor, .Allocator, .Constructor, .Destructor, .Variable, .Subscript, .ExplicitClosure, .ImplicitClosure, .Initializer, .PropertyWrapperBackingInitializer, .PropertyWrapperInitFromProjectedValue, .DefaultArgumentInitializer:
            NumToCopy = numberOfChildren
            fallthrough
        case .Structure, .Enum, .Class, .TypeAlias, .OtherNominalType:
            let result = Node(kind)
            var parentOrModule: Node? = firstChild
            if parentOrModule?.isSpecialized == true {
                parentOrModule = parentOrModule?.unspecialized()
            }
            result.addChild(parentOrModule)
            if NumToCopy > 0 {
                for index in 0..<NumToCopy {
                    result.addChild(getChild(index))
                }
            }
            return result
            
        case .BoundGenericStructure, .BoundGenericEnum, .BoundGenericClass, .BoundGenericProtocol, .BoundGenericOtherNominalType, .BoundGenericTypeAlias:
            let unboundType = getChild(0)
            assert(unboundType.getKind() == .Type)
            let nominalType = unboundType.getChild(0)
            if nominalType.isSpecialized {
                return nominalType.unspecialized()
            }
            return nominalType
        case .BoundGenericFunction:
            let unboundFunction = getChild(0)
            assert(unboundFunction.getKind() == .Function || unboundFunction.getKind() == .Constructor)
            if unboundFunction.isSpecialized {
                return unboundFunction.unspecialized()
            }
            return unboundFunction
        case .Extension:
            let parent = getChild(1)
            if !parent.isSpecialized {
                return self
            }
            let result = Node(.Extension)
            result.addChild(firstChild)
            result.addChild(parent.unspecialized())
            if numberOfChildren == 3 {
                // Add the generic signature of the extension.
                result.addChild(getChild(2))
            }
            return result
        default:
            assertionFailure("bad nominal type kind")
        }
        return nil
    }

    func extractSymbolKind() -> Kind? {
        switch kind {
        case .Global:
            // Global nodes wrap the actual kind as first child
            // Skip function attributes to get to the real symbol kind
            for child in copyOfChildren where !child.kind.isFunctionAttr {
                return child.kind
            }
            return nil
        case .TypeMangling:
            // Type manglings wrap the actual type
            return firstChild.extractSymbolKind()
        case .Type:
            // Type nodes wrap the actual kind
            return firstChild.extractSymbolKind()
        default:
            // For all other cases, the current kind is the symbol kind
            return kind
        }
    }
}
