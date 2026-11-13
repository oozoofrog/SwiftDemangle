//
//  Node+KindClassification.swift
//  Demangling
//

import Foundation

extension Node.Kind {
    
    private static let declNames: [Node.Kind] = [
        .Identifier,
        .LocalDeclName,
        .PrivateDeclName,
        .RelatedEntityDeclName,
        .PrefixOperator,
        .PostfixOperator,
        .InfixOperator,
        .TypeSymbolicReference,
        .ProtocolSymbolicReference,
        .ObjectiveCProtocolSymbolicReference
    ]
    private static let anyGenerics: [Node.Kind] = [
        .Structure,
        .Class,
        .Enum,
        .Protocol,
        .ProtocolSymbolicReference,
        .ObjectiveCProtocolSymbolicReference,
        .OtherNominalType,
        .TypeAlias,
        .TypeSymbolicReference,
        .BuiltinTupleType
    ]
    private static let requirements: [Node.Kind] = [
        .DependentGenericParamPackMarker,
        .DependentGenericParamValueMarker,
        .DependentGenericSameTypeRequirement,
        .DependentGenericSameShapeRequirement,
        .DependentGenericLayoutRequirement,
        .DependentGenericConformanceRequirement,
        .DependentGenericInverseConformanceRequirement
    ]
    private static let contexts: [Node.Kind] = [
        .Allocator,
        .BorrowAccessor,
        .MutateAccessor,
        .AnonymousContext,
        .Class,
        .Constructor,
        .Deallocator,
        .DefaultArgumentInitializer,
        .Destructor,
        .DidSet,
        .Enum,
        .ExplicitClosure,
        .Extension,
        .Function,
        .Getter,
        .GlobalGetter,
        .IVarInitializer,
        .IVarDestroyer,
        .ImplicitClosure,
        .Initializer,
        .InitAccessor,
        .IsolatedDeallocator,
        .MaterializeForSet,
        .ModifyAccessor,
        .YieldingMutateAccessor,
        .Module,
        .NativeOwningAddressor,
        .NativeOwningMutableAddressor,
        .NativePinningAddressor,
        .NativePinningMutableAddressor,
        .OtherNominalType,
        .OwningAddressor,
        .OwningMutableAddressor,
        .PropertyWrapperBackingInitializer,
        .PropertyWrappedFieldInitAccessor,
        .PropertyWrapperInitFromProjectedValue,
        .Protocol,
        .ProtocolSymbolicReference,
        .ReadAccessor,
        .YieldingBorrowAccessor,
        .Setter,
        .Static,
        .Structure,
        .Subscript,
        .TypeSymbolicReference,
        .TypeAlias,
        .UnsafeAddressor,
        .UnsafeMutableAddressor,
        .Variable,
        .WillSet,
        .OpaqueReturnTypeOf,
        .AutoDiffFunction
    ]
    private static let functionAttrs: [Node.Kind] = [
        .FunctionSignatureSpecialization,
        .GenericSpecialization,
        .GenericSpecializationPrespecialized,
        .InlinedGenericFunction,
        .GenericSpecializationNotReAbstracted,
        .GenericPartialSpecialization,
        .GenericPartialSpecializationNotReAbstracted,
        .GenericSpecializationInResilienceDomain,
        .ObjCAttribute,
        .NonObjCAttribute,
        .DynamicAttribute,
        .DirectMethodReferenceAttribute,
        .VTableAttribute,
        .PartialApplyForwarder,
        .PartialApplyObjCForwarder,
        .OutlinedVariable,
        .OutlinedReadOnlyObject,
        .OutlinedBridgedMethod,
        .MergedFunction,
        .DistributedThunk,
        .DistributedAccessor,
        .DynamicallyReplaceableFunctionImpl,
        .DynamicallyReplaceableFunctionKey,
        .DynamicallyReplaceableFunctionVar,
        .AsyncFunctionPointer,
        .AsyncAwaitResumePartialFunction,
        .AsyncSuspendResumePartialFunction,
        .AccessibleFunctionRecord,
        .BackDeploymentThunk,
        .BackDeploymentFallback,
        .CoroFunctionPointer,
        .DefaultOverride,
        .HasSymbolQuery,
    ]
    
    var isDeclName: Bool {
        Self.declNames.contains(self)
    }
    
    var isAnyGeneric: Bool {
        Self.anyGenerics.contains(self)
    }
    
    var isEntity: Bool {
        if self == .Type {
            return true
        } else {
            return isContext
        }
    }
    
    var isRequirement: Bool {
        Self.requirements.contains(self)
    }
    
    var isContext: Bool {
        Self.contexts.contains(self)
    }
    
    var isFunctionAttr: Bool {
        Self.functionAttrs.contains(self)
    }
    
    var isMacroExpansion: Bool {
        switch self {
        case .AccessorAttachedMacroExpansion,
                .MemberAttributeAttachedMacroExpansion,
                .FreestandingMacroExpansion,
                .MemberAttachedMacroExpansion,
                .PeerAttachedMacroExpansion,
                .ConformanceAttachedMacroExpansion,
                .ExtensionAttachedMacroExpansion,
                .MacroExpansionLoc:
            return true
        default:
            return false
        }
    }
}
