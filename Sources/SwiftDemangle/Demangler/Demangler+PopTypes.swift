//
//  Demangler+PopTypes.swift
//  Demangling
//

import Foundation

extension Demangler {
    func popFunctionType(_ kind: Node.Kind, _ hasClangType: Bool = false) -> Node? {
        var FuncType: Node? = createNode(kind)
        var ClangType: Node?
        if hasClangType {
            ClangType = demangleClangType()
        }
        addChild(FuncType, ClangType)
        addChild(FuncType, popNode(.SendingResultFunctionType))
        addChild(FuncType, popNode({ kind in
            kind == .GlobalActorFunctionType ||
            kind == .IsolatedAnyFunctionType ||
            kind == .NonIsolatedCallerFunctionType
        }))
        addChild(FuncType, popNode(.DifferentiableFunctionType))
        addChild(FuncType, popNode({ kind in
            return kind == .ThrowsAnnotation ||
                kind == .TypedThrowsAnnotation
        }))
        addChild(FuncType, popNode(.ConcurrentFunctionType))
        addChild(FuncType, popNode(.AsyncAnnotation))

        FuncType = addChild(FuncType, popFunctionParams(.ArgumentTuple))
        FuncType = addChild(FuncType, popFunctionParams(.ReturnType))
        return createType(FuncType)
    }
    
    func popFunctionParams(_ kind: Node.Kind) -> Node? {
        var ParamsType: Node?
        if popNode(.EmptyList) != nil {
            ParamsType = createType(createNode(.Tuple))
        } else {
            ParamsType = popNode(.Type)
        }
        return createWithChild(kind, ParamsType)
    }

    func popFunctionParamLabels(_ Type: Node?) -> Node? {
        if !IsOldFunctionTypeMangling, popNode(.EmptyList).hasValue {
            return createNode(.LabelList)
        }

        guard let Type = Type, Type.getKind() == .Type else { return nil }

        var FuncType = Type.getFirstChild()
        if FuncType.getKind() == .DependentGenericType {
            FuncType = FuncType.getChild(1).getFirstChild()
        }

        if FuncType.getKind() != .FunctionType, FuncType.getKind() != .NoEscapeFunctionType {
            return nil
        }

        var FirstChildIdx = 0
        if FuncType.getChild(FirstChildIdx).getKind() == .SendingResultFunctionType {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .GlobalActorFunctionType {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .IsolatedAnyFunctionType {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .NonIsolatedCallerFunctionType {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .DifferentiableFunctionType {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .ThrowsAnnotation ||
            FuncType.getChild(FirstChildIdx).getKind() == .TypedThrowsAnnotation {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .ConcurrentFunctionType {
            ++FirstChildIdx
        }
        if FuncType.getChild(FirstChildIdx).getKind() == .AsyncAnnotation {
            ++FirstChildIdx
        }
        let ParameterType = FuncType.getChild(FirstChildIdx)

        assert(ParameterType.getKind() == .ArgumentTuple)

        assert(ParameterType.getKind() == .ArgumentTuple)

        let ParamsType = ParameterType.getFirstChild()
        assert(ParamsType.getKind() == .Type)
        let Params = ParamsType.getFirstChild()
        let NumParams = Params.getKind() == .Tuple ? Params.getNumChildren() : 1

        if NumParams == 0 {
            return nil
        }

        func getChildIf(_ node: Node, _ filterBy: Node.Kind) -> (offset: Int, element: Node)? {
            for i in 0..<node.getNumChildren() {
                let Child = node.getChild(i)
                if Child.getKind() == filterBy {
                    return (i, Child)
                }
            }
            return nil
        }

        func getLabel(_ Params: Node, _ Idx: Int) -> Node? {
            // Old-style function type mangling has labels as part of the argument.
            if IsOldFunctionTypeMangling {
                let Param = Params.getChild(Idx)
                if let Label = getChildIf(Param, .TupleElementName) {
                    Param.removeChildAt(Label.offset)
                    return createNodeWithAllocatedText(.Identifier, Label.element.getText())
                }

                return createNode(.FirstElementMarker)
            }

            return popNode()
        }

        let LabelList = createNode(.LabelList)
        let Tuple = ParameterType.getFirstChild().getFirstChild()

        if IsOldFunctionTypeMangling && Tuple.getKind() != .Tuple {
            return LabelList
        }

        var hasLabels = false
        for i in 0..<NumParams {
            guard let Label = getLabel(Tuple, i) else { return nil }

            if Label.getKind() != .Identifier && Label.getKind() != .FirstElementMarker {
                return nil
            }

            LabelList.addChild(Label)

            hasLabels = hasLabels || Label.getKind() != .FirstElementMarker
        }

        // Old style label mangling can produce label list without
        // actual labels, we need to support that case specifically.
        if !hasLabels {
            return createNode(.LabelList)
        }

        if !IsOldFunctionTypeMangling {
            LabelList.reverseChildren()
        }

        return LabelList
    }
    
    func popTuple() -> Node? {
        let Root = createNode(.Tuple)
        
        if !popNode(.EmptyList) {
            var firstElem = false
            repeat {
                firstElem = popNode(.FirstElementMarker).hasValue
                let TupleElmt = createNode(.TupleElement)
                addChild(TupleElmt, popNode(.VariadicMarker))
                if let Ident = popNode(.Identifier) {
                    TupleElmt.addChild(createNodeWithAllocatedText(.TupleElementName, Ident.getText()))
                }
                guard let Ty = popNode(.Type) else { return nil }
                TupleElmt.addChild(Ty)
                Root.addChild(TupleElmt)
            } while !firstElem
            
            Root.reverseChildren()
        }
        return createType(Root)
    }

    func popPack() -> Node? {
        let Root = createNode(.Pack)

        if popNode(.EmptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = popNode(.FirstElementMarker).hasValue
                guard let Ty = popNode(.Type) else { return nil }
                Root.addChild(Ty)
            } while !firstElem
            
            Root.reverseChildren()
        }
        return createType(Root)
    }

    func popSILPack() -> Node? {
        var Root: Node?

        switch (nextChar()) {
        case "d":
            Root = createNode(.SILPackDirect)
        case "i":
            Root = createNode(.SILPackIndirect)
        default:
            return nil
        }

        if !popNode(.EmptyList) {
            var firstElem = false
            repeat {
                firstElem = popNode(.FirstElementMarker).hasValue
                guard let Ty = popNode(.Type) else { return nil }
                Root?.addChild(Ty)
            } while !firstElem

            Root?.reverseChildren()
        }

        return createType(Root)
    }
    
    func popTypeList() -> Node? {
        let Root = createNode(.TypeList)
        
        if !popNode(.EmptyList) {
            var firstElem = false
            repeat {
                firstElem = popNode(.FirstElementMarker).hasValue
                guard let Ty = popNode(.Type) else { return nil }
                Root.addChild(Ty)
            } while !firstElem
            
            Root.reverseChildren()
        }
        return Root
    }
    
    func popProtocol() -> Node? {
        if let type = popNode(.Type) {
            guard type.numberOfChildren > 0 else { return nil }
            
            guard type.isProtocol else { return nil }
            
            return type
        }
        
        if let  symbolicRef = popNode(.ProtocolSymbolicReference) {
            return symbolicRef
        } else if let objcSymbolicRef = popNode(.ObjectiveCProtocolSymbolicReference) {
            return objcSymbolicRef
        }
        
        let Name = popNode(isDeclName)
        let Ctx = popContext()
        let Proto = createWithChildren(.Protocol, Ctx, Name)
        return createType(Proto)
    }
    
    func popAnyProtocolConformanceList() -> Node? {
        let conformanceList = createNode(.AnyProtocolConformanceList)
        if popNode(.EmptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = popNode(.FirstElementMarker).hasValue
                guard let anyConformance = popAnyProtocolConformance() else { return nil }
                conformanceList.addChild(anyConformance)
            } while !firstElem
            
            conformanceList.reverseChildren()
        }
        return conformanceList
    }
    
    func popAnyProtocolConformance() -> Node? {
        return popNode(
            { kind in
                switch (kind) {
                case .ConcreteProtocolConformance,
                        .PackProtocolConformance,
                        .DependentProtocolConformanceRoot,
                        .DependentProtocolConformanceInherited,
                        .DependentProtocolConformanceAssociated,
                        .DependentProtocolConformanceOpaque:
                    return true
                default:
                    return false
                }
            })
    }
    
    
    func popDependentProtocolConformance() -> Node? {
        return popNode({ kind in
            switch (kind) {
            case .DependentProtocolConformanceRoot, .DependentProtocolConformanceInherited, .DependentProtocolConformanceAssociated:
                return true
            default:
                return false
            }
        })
    }
    
    
    func popDependentAssociatedConformance() -> Node? {
        let proto = popProtocol()
        let dependentType = popNode(.Type)
        return createWithChildren(.DependentAssociatedConformance, dependentType, proto)
    }
    
    func popAssocTypeName() -> Node? {
        var proto = popNode(.Type)
        if proto != nil && !proto.isProtocol {
            return nil
        }
        
        // If we haven't seen a protocol, check for a symbolic reference.
        if proto == nil {
            proto = popNode(.ProtocolSymbolicReference)
        }
        if proto == nil {
            proto = popNode(.ObjectiveCProtocolSymbolicReference)
        }
        
        let identifier = popNode(.Identifier)
        let assocTy = createWithChild(.DependentAssociatedTypeRef, identifier)
        addChild(assocTy, proto)
        return assocTy
    }
    
    func popAssocTypePath() -> Node? {
        let assocTypePath = createNode(.AssocTypePath)
        var firstElem = false
        repeat {
            firstElem = popNode(.FirstElementMarker) != nil
            guard let assocTy = popAssocTypeName() else { return nil }
            assocTypePath.add(assocTy)
        } while !firstElem
        assocTypePath.reverseChildren()
        return assocTypePath
    }
    
    func isGenericParamType(_ node: Node?) -> Bool {
        guard let node else { return false }
        switch node.getKind() {
        case .Type:
            return isGenericParamType(node.copyOfChildren.first)
        case .DependentGenericParamType:
            return true
        default:
            return false
        }
    }
    
    func popAssociatedConformanceWitnessAccessorSubject() -> Node? {
        if let type = popNode(.Type) {
            if isGenericParamType(type) {
                return type
            }
            
            pushNode(type)
        }
        
        return popAssocTypePath()
    }
    
    func popProtocolConformance() -> Node? {
        let genSig = popNode(.DependentGenericSignature)
        let module = popModule()
        let proto = popProtocol()
        var type = popNode(.Type)
        var ident: Node?
        if type == nil {
            // Property behavior conformance
            ident = popNode(.Identifier)
            type = popNode(.Type)
        }
        if genSig != nil {
            type = createType(createWithChildren(.DependentGenericType, genSig, type))
        }
        let conf = createWithChildren(.ProtocolConformance, type, proto, module)
        addChild(conf, ident)
        return conf
    }
}
