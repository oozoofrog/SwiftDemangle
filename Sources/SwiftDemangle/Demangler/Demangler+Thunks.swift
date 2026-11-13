//
//  Demangler+Thunks.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleThunkOrSpecialization() -> Node? {
        let c = nextChar()
        switch c {
        case "T":
            switch nextChar() {
            case "I":
                return createWithChild(.SILThunkIdentity, popNode(isEntity))
            case "H":
                return createWithChild(.SILThunkHopToMainActorIfNeeded, popNode(isEntity))
            default:
                return nil
            }
        case "c":
            return createWithChild(.CurryThunk, popNode(isEntity))
        case "j":
            return createWithChild(.DispatchThunk, popNode(isEntity))
        case "q":
            return createWithChild(.MethodDescriptor, popNode(isEntity))
        case "o":
            return createNode(.ObjCAttribute)
        case "O":
            return createNode(.NonObjCAttribute)
        case "D":
            return createNode(.DynamicAttribute)
        case "d":
            return createNode(.DirectMethodReferenceAttribute)
        case "E":
            return createNode(.DistributedThunk)
        case "F":
            return createNode(.DistributedAccessor)
        case "a":
            return createNode(.PartialApplyObjCForwarder)
        case "A":
            return createNode(.PartialApplyForwarder)
        case "m":
            return createNode(.MergedFunction)
        case "X":
            return createNode(.DynamicallyReplaceableFunctionVar)
        case "x":
            return createNode(.DynamicallyReplaceableFunctionKey)
        case "I":
            return createNode(.DynamicallyReplaceableFunctionImpl)
        case "Y", "Q":
            let discriminator = demangleIndexAsNode()
            return createWithChild(c == "Q" ? .AsyncAwaitResumePartialFunction : .AsyncSuspendResumePartialFunction, discriminator)
        case "C":
            let type = popNode(.Type)
            return createWithChild(.CoroutineContinuationPrototype, type)
        case "z", "Z":
            let flagMode = demangleIndexAsNode()
            let sig = popNode(.DependentGenericSignature)
            let resultType = popNode(.Type)
            let implType = popNode(.Type)
            let node = createWithChildren(c == "z" ? .ObjCAsyncCompletionHandlerImpl : .CheckedObjCAsyncCompletionHandlerImpl, implType, resultType, flagMode)
            if sig.hasValue {
                addChild(node, sig)
            }
            return node
        case "V":
            let Base = popNode(isEntity)
            let Derived = popNode(isEntity)
            return createWithChildren(.VTableThunk, Derived, Base)
        case "W":
            let Entity = popNode(isEntity)
            let Conf = popProtocolConformance()
            return createWithChildren(.ProtocolWitness, Conf, Entity)
        case "S":
            return createWithChild(.ProtocolSelfConformanceWitness, popNode(isEntity))
        case "R", "r", "y":
            let kind: Node.Kind
            if c == "R" { kind = .ReabstractionThunkHelper }
            else if c == "y" { kind = .ReabstractionThunkHelperWithSelf }
            else { kind = .ReabstractionThunk }
            let Thunk = createNode(kind)
            if let GenSig = popNode(.DependentGenericSignature) {
                addChild(Thunk, GenSig)
            }
            if kind == .ReabstractionThunkHelperWithSelf {
                addChild(Thunk, popNode(.Type))
            }
            addChild(Thunk, popNode(.Type))
            addChild(Thunk, popNode(.Type))
            return Thunk
        case "g":
            return demangleGenericSpecialization(.GenericSpecialization)
        case "G":
            return demangleGenericSpecialization(.GenericSpecializationNotReAbstracted)
        case "B":
            return demangleGenericSpecialization(.GenericSpecializationInResilienceDomain)
        case "t":
            return demangleGenericSpecializationWithDroppedArguments()
        case "s":
            return demangleGenericSpecialization(.GenericSpecializationPrespecialized)
        case "i":
            return demangleGenericSpecialization(.InlinedGenericFunction)
        case "p":
            let Spec = demangleSpecAttributes(.GenericPartialSpecialization)
            let Param = createWithChild(.GenericSpecializationParam, popNode(.Type))
            return addChild(Spec, Param)
        case"P":
            let Spec = demangleSpecAttributes(.GenericPartialSpecializationNotReAbstracted)
            let Param = createWithChild(.GenericSpecializationParam, popNode(.Type))
            return addChild(Spec, Param)
        case"f":
            return demangleFunctionSpecialization()
        case "K", "k":
            let nodeKind: Node.Kind
            if nextIf("mu") {
                nodeKind = .KeyPathUnappliedMethodThunkHelper
            } else if nextIf("MA") {
                nodeKind = .KeyPathAppliedMethodThunkHelper
            } else {
                nodeKind = c == "K" ? .KeyPathGetterThunkHelper : .KeyPathSetterThunkHelper
            }

            let isSerialized = nextIf("q")
            
            var types: [Node] = []
            var node = popNode()
            if node == nil || node?.getKind() != .Type {
                return nil
            }
            repeat {
                types.append(node)
                node = popNode()
            } while node.hasValue && node.getKind() == .Type
            
            var result: Node?
            if node.hasValue {
                if node.getKind() == .DependentGenericSignature {
                    guard let decl = popNode() else { return nil }
                    result = createWithChildren(nodeKind, decl, /*sig*/ node)
                } else {
                    result = createWithChild(nodeKind, /*decl*/ node)
                }
            } else {
                return nil
            }
            for node in types.reversed() {
                result.add(node)
            }
            
            if isSerialized {
                result.addChild(createNode(.IsSerialized))
            }
            
            return result
        case "l":
            guard let assocTypeName = popAssocTypeName() else { return nil }
            
            return createWithChild(.AssociatedTypeDescriptor, assocTypeName)
        case "L":
            return createWithChild(.ProtocolRequirementsBaseDescriptor, popProtocol())
        case "M":
            return createWithChild(.DefaultAssociatedTypeMetadataAccessor, popAssocTypeName())
            
        case "n":
            let requirementTy = popProtocol()
            let conformingType = popAssociatedConformanceWitnessAccessorSubject()
            let protoTy = popNode(.Type)
            return createWithChildren(.AssociatedConformanceDescriptor, protoTy, conformingType, requirementTy)
        case "N":
            let requirementTy = popProtocol()
            let assocTypePath = popAssociatedConformanceWitnessAccessorSubject()
            let protoTy = popNode(.Type)
            return createWithChildren(.DefaultAssociatedConformanceAccessor, protoTy, assocTypePath, requirementTy)
        case "b":
            let requirementTy = popProtocol()
            let protoTy = popNode(.Type)
            return createWithChildren(.BaseConformanceDescriptor, protoTy, requirementTy)
        case "H", "h":
            let nodeKind: Node.Kind = c == "H" ? .KeyPathEqualsThunkHelper : .KeyPathHashThunkHelper
            
            let isSerialized = nextIf("q")
            
            var genericSig: Node?
            var types: [Node] = []
            
            if let node = popNode() {
                if node.getKind() == .DependentGenericSignature {
                    genericSig = node
                } else if node.getKind() == .Type {
                    types.append(node)
                } else {
                    return nil
                }
            } else {
                return nil
            }
            
            while let node = popNode() {
                if node.getKind() != .Type {
                    return nil
                }
                types.push_back(node)
            }
            
            let result = createNode(nodeKind)
            for type in types.reversed() {
                result.addChild(type)
            }
            if genericSig.hasValue {
                result.addChild(genericSig)
            }
            
            if isSerialized {
                result.addChild(createNode(.IsSerialized))
            }
            
            return result
        case "v":
            let Idx = demangleIndex()
            if Idx < 0 {
                return nil
            }
            if nextChar() == "r" {
                return createNode(.OutlinedReadOnlyObject, Idx)
            } else {
                return createNode(.OutlinedVariable, Idx)
            }
        case "e":
            let Params = demangleBridgedMethodParams()
            if Params.isEmpty {
                return nil
            }
            return createNode(.OutlinedBridgedMethod, Params)
        case "u": return createNode(.AsyncFunctionPointer)
        case "U":
            guard let globalActor = popNode(.Type) else { return nil }
            
            guard let reabstraction = popNode() else { return nil }
            
            let node = createNode(.ReabstractionThunkHelperWithGlobalActor)
            node.addChild(reabstraction)
            node.addChild(globalActor)
            return node
        case "J":
            switch peekChar() {
            case "S":
                nextChar()
                return demangleAutoDiffSubsetParametersThunk()
            case "O":
                nextChar()
                return demangleAutoDiffSelfReorderingReabstractionThunk()
            case "V":
                nextChar()
                return demangleAutoDiffFunctionOrSimpleThunk(.AutoDiffDerivativeVTableThunk)
            default:
                return demangleAutoDiffFunctionOrSimpleThunk(.AutoDiffFunction)
            }
        case "w":
            switch (nextChar()) {
            case "b": return createNode(.BackDeploymentThunk)
            case "B": return createNode(.BackDeploymentFallback)
            case "c": return createNode(.CoroFunctionPointer)
            case "d": return createNode(.DefaultOverride)
            case "S": return createNode(.HasSymbolQuery)
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
    func demangleAutoDiffFunctionOrSimpleThunk(_ nodeKind: Node.Kind) -> Node? {
        var result: Node? = createNode(nodeKind)
        while let originalNode = popNode() {
            result = addChild(result, originalNode)
        }
        result.reverseChildren()
        let kind = demangleAutoDiffFunctionKind()
        result = addChild(result, kind)
        result = addChild(result, demangleIndexSubset())
        guard nextIf("p") else { return nil }
        result = addChild(result, demangleIndexSubset())
        guard nextIf("r") else { return nil }
        return result
    }
    
    func demangleAutoDiffFunctionKind() -> Node? {
        let kind = nextChar()
        if kind != "f" && kind != "r" && kind != "d" && kind != "p" {
            return nil
        }
        return createNode(.AutoDiffFunctionKind, kind)
    }
    
    func demangleAutoDiffSubsetParametersThunk() -> Node? {
        var result: Node? = createNode(.AutoDiffSubsetParametersThunk)
        while let node = popNode() {
            result = addChild(result, node)
        }
        result.reverseChildren()
        let kind = demangleAutoDiffFunctionKind()
        result = addChild(result, kind)
        result = addChild(result, demangleIndexSubset())
        guard nextIf("p") else { return nil }
        result = addChild(result, demangleIndexSubset())
        guard nextIf("r") else { return nil }
        result = addChild(result, demangleIndexSubset())
        guard nextIf("P") else { return nil }
        return result
    }
    
    func demangleAutoDiffSelfReorderingReabstractionThunk() -> Node? {
        var result: Node? = createNode(.AutoDiffSelfReorderingReabstractionThunk)
        addChild(result, popNode(.DependentGenericSignature))
        result = addChild(result, popNode(.Type))
        result = addChild(result, popNode(.Type))
        result.reverseChildren()
        result = addChild(result, demangleAutoDiffFunctionKind())
        return result
    }
    
    func demangleDifferentiabilityWitness() -> Node? {
        var result: Node? = createNode(.DifferentiabilityWitness)
        let optionalGenSig = popNode(.DependentGenericSignature)
        while let node = popNode() {
            result = addChild(result, node)
        }
        result?.reverseChildren()
        let kind: MangledDifferentiabilityKind
        let c = nextChar()
        switch c {
        case "f":
            kind = .forward
        case "r":
            kind = .reverse
        case "d":
            kind = .normal
        case "l":
            kind = .linear
        default:
            return nil
        }
        result = addChild(result, createNode(.Index, kind))
        result = addChild(result, demangleIndexSubset())
        if !nextIf("p") {
            return nil
        }
        result = addChild(result, demangleIndexSubset())
        if !nextIf("r") {
            return nil
        }
        addChild(result, optionalGenSig)
        return result
    }
    
    func demangleIndexSubset() -> Node? {
        var str = ""
        while peekChar() == "S" || peekChar() == "U" {
            str.append(peekChar())
            nextChar()
        }
        if str.isEmpty {
            return nil
        }
        return createNode(.IndexSubset, str)
    }
    
    func demangleDifferentiableFunctionType() -> Node? {
        let kind: MangledDifferentiabilityKind
        let c = nextChar()
        switch c {
        case "f":
            kind = .forward
        case "r":
            kind = .reverse
        case "d":
            kind = .normal
        case "l":
            kind = .linear
        default:
            return nil
        }
        return createNode(.DifferentiableFunctionType, kind)
    }
}
