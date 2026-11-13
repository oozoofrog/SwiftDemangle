//
//  Node+NominalOwner.swift
//  SwiftDemangle
//

extension Node {
    func extractNominalOwner() -> Node? {
        var current: Node? = self
        while let node = current {
            switch node.kind {
            case .Class, .Structure, .Enum, .Protocol, .OtherNominalType:
                return node

            case .Global, .PartialApplyForwarder, .PartialApplyObjCForwarder:
                current = node.nominalOwnerTarget

            case .Extension, .AnonymousContext:
                // Child 0 is the extension's module or the anonymous context's name.
                current = node.copyOfChildren.dropFirst().first

            case .TypeMangling:
                // Function type manglings can have a LabelList before the Type.
                current = node.childIf(.Type)

            case .FieldOffset:
                // Child 0 is the directness; the stored property follows it.
                current = node.childIf(.Variable)

            case .Type,
                    .BoundGenericClass, .BoundGenericStructure, .BoundGenericEnum,
                    .BoundGenericProtocol, .BoundGenericOtherNominalType,
                    .BoundGenericTypeAlias, .BoundGenericFunction,
                    .Static, .CurryThunk, .DispatchThunk, .MethodDescriptor,
                    .PropertyDescriptor,
                    .TypeMetadata, .TypeMetadataAccessFunction, .FullTypeMetadata,
                    .TypeMetadataLazyCache, .GenericTypeMetadataPattern,
                    .TypeMetadataInstantiationFunction, .TypeMetadataInstantiationCache,
                    .TypeMetadataCompletionFunction, .TypeMetadataSingletonInitializationCache,
                    .Metaclass, .ClassMetadataBaseOffset, .MethodLookupFunction,
                    .ObjCResilientClassStub, .FullObjCResilientClassStub,
                    .ObjCMetadataUpdateFunction, .ValueWitnessTable,
                    .ReflectionMetadataFieldDescriptor, .ReflectionMetadataBuiltinDescriptor,
                    .ReflectionMetadataSuperclassDescriptor,
                    .NominalTypeDescriptor, .NominalTypeDescriptorRecord,
                    .ProtocolDescriptor, .ProtocolDescriptorRecord:
                // These wrappers put the declaration/type before any other payload.
                current = node.copyOfChildren.first

            case .Function, .Variable, .Subscript, .TypeAlias,
                    .Allocator, .Constructor, .Deallocator, .Destructor,
                    .IsolatedDeallocator, .IVarInitializer, .IVarDestroyer,
                    .ExplicitClosure, .ImplicitClosure, .DefaultArgumentInitializer,
                    .Initializer, .PropertyWrapperBackingInitializer,
                    .PropertyWrappedFieldInitAccessor,
                    .PropertyWrapperInitFromProjectedValue,
                    .Getter, .Setter, .GlobalGetter, .WillSet, .DidSet,
                    .ReadAccessor, .YieldingBorrowAccessor, .ModifyAccessor, .YieldingMutateAccessor,
                    .InitAccessor, .BorrowAccessor, .MutateAccessor, .MaterializeForSet,
                    .OwningAddressor, .OwningMutableAddressor,
                    .NativeOwningAddressor, .NativeOwningMutableAddressor,
                    .NativePinningAddressor, .NativePinningMutableAddressor,
                    .UnsafeAddressor, .UnsafeMutableAddressor:
                // Only declaration contexts establish ownership, never signatures.
                current = node.copyOfChildren.first

            default:
                // Unknown shapes must not acquire an owner from an arbitrary child.
                return nil
            }
        }
        return nil
    }

    private var nominalOwnerTarget: Node? {
        let candidates = copyOfChildren.filter { child in
            switch child.kind {
            case .PartialApplyForwarder, .PartialApplyObjCForwarder:
                // Unlike marker attributes, these contain the forwarded declaration.
                return true
            case .Suffix:
                return false
            default:
                return !child.kind.isFunctionAttr
            }
        }
        // Multiple non-attribute children do not identify a unique declaration.
        return candidates.count == 1 ? candidates.first : nil
    }
}
