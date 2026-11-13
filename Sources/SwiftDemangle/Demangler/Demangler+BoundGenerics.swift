//
//  Demangler+BoundGenerics.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleAnyGenericType(_ kind: Node.Kind) -> Node? {
        let Name = popNode(isDeclName)
        let Ctx = popContext()
        let NTy = createType(createWithChildren(kind, Ctx, Name))
        addSubstitution(NTy)
        return NTy
    }
    
    func demangleExtensionContext() -> Node? {
        let GenSig = popNode(.DependentGenericSignature)
        let Module = popModule()
        let type = popTypeAndGetAnyGeneric()
        var Ext = createWithChildren(.Extension, Module, type)
        if let gensig = GenSig {
            Ext = addChild(Ext, gensig)
        }
        return Ext
    }
    
    @discardableResult
    func setParentForOpaqueReturnTypeNodes(parent: Node?, visitedNode: Node?) -> Node? {
        guard let parent, let visitedNode else {
            return nil
        }
        if visitedNode.kind == .OpaqueReturnType {
            if visitedNode.numberOfChildren > 0, visitedNode.lastChild.getKind() == .OpaqueReturnTypeParent {
                return parent
            }
            visitedNode.add(createNode(.OpaqueReturnTypeParent, parent.index ?? 0))
            return parent
        }
        
        // If this node is one that may in turn define its own opaque return type,
        // stop recursion, since any opaque return type nodes underneath would refer
        // to the nested declaration rather than the one we're looking at.
        switch visitedNode.kind {
        case .Function,
                .Variable,
                .Subscript:
            return parent
        default:
            for index in 0..<visitedNode.numberOfChildren {
                setParentForOpaqueReturnTypeNodes(parent: parent, visitedNode: visitedNode.children(index))
            }
            // An opaque return type below may have gained its parent node.
            visitedNode.recomputeHeight()
            return parent
        }
    }
    
    func demanglePlainFunction() -> Node? {
        let GenSig = popNode(.DependentGenericSignature)
        var type = popFunctionType(.FunctionType)
        let LabelList = popFunctionParamLabels(type)
        
        if GenSig.hasValue {
            type = createType(createWithChildren(.DependentGenericType, GenSig, type))
        }
        
        let Name = popNode(isDeclName)
        let Ctx = popContext()
        
        var result: Node?
        if LabelList.hasValue {
            result = createWithChildren(.Function, Ctx, Name, LabelList, type)
        } else {
            result = createWithChildren(.Function, Ctx, Name, type)
        }
        
        result = setParentForOpaqueReturnTypeNodes(parent: result, visitedNode: type)
        result?.recomputeHeight()
        return result
    }
    
    func demangleRetroactiveProtocolConformanceRef() -> Node? {
        let module = popModule()
        let proto = popProtocol()
        let protocolConformanceRef = createWithChildren(.ProtocolConformanceRefInOtherModule, proto, module)
        return protocolConformanceRef
    }
    
    func demangleConcreteProtocolConformance() -> Node? {
        let conditionalConformanceList = popAnyProtocolConformanceList()
        
        var conformanceRef = popNode(.ProtocolConformanceRefInTypeModule)
        if conformanceRef == nil {
            conformanceRef = popNode(.ProtocolConformanceRefInProtocolModule)
        }
        if !conformanceRef {
            conformanceRef = demangleRetroactiveProtocolConformanceRef()
        }
        
        let type = popNode(.Type)
        return createWithChildren(.ConcreteProtocolConformance, type, conformanceRef, conditionalConformanceList)
    }
    
    func demanglePackProtocolConformance() -> Node? {
        let patternConformanceList = popAnyProtocolConformanceList()
        
        return createWithChild(.PackProtocolConformance, patternConformanceList)
    }
    
    func demangleDependentProtocolConformanceRoot() -> Node? {
        let index = demangleDependentConformanceIndex()
        let proto = popProtocol()
        let dependentType = popNode(.Type)
        return createWithChildren(.DependentProtocolConformanceRoot, dependentType, proto, index)
    }
    
    func demangleDependentProtocolConformanceInherited() -> Node? {
        let index = demangleDependentConformanceIndex()
        let proto = popProtocol()
        let nested = popDependentProtocolConformance()
        return createWithChildren(.DependentProtocolConformanceInherited, nested, proto, index)
    }
    
    func demangleDependentProtocolConformanceAssociated() -> Node? {
        let index = demangleDependentConformanceIndex()
        let associatedConformance = popDependentAssociatedConformance()
        let nested = popDependentProtocolConformance()
        return createWithChildren(.DependentProtocolConformanceAssociated, nested, associatedConformance, index)
    }

    func demangleDependentProtocolConformanceOpaque() -> Node? {
        let type = popNode(.Type)
        let conformance = popDependentProtocolConformance()
        return createWithChildren(.DependentProtocolConformanceOpaque, conformance, type)
    }
    
    func demangleDependentConformanceIndex() -> Node? {
        let index = demangleIndex()
        // index < 0 indicates a demangling error.
        // index == 0 is ill-formed by the (originally buggy) use of this production.
        guard index > 0 else { return nil }
        
        // index == 1 indicates an unknown index.
        guard index != 1 else { return createNode(.UnknownIndex) }
        
        // Remove the index adjustment.
        return createNode(.Index, index - 2)
    }
    
    func demangleRetroactiveConformance() -> Node? {
        let index = demangleIndexAsNode()
        let conformance = popAnyProtocolConformance()
        return createWithChildren(.RetroactiveConformance, index, conformance)
    }
    
    func demangleBoundGenerics(_ TypeListList: inout [Node], _ RetroactiveConformances: inout Node?) -> Bool {
        var RetroactiveConformances: Node?
        while let RetroactiveConformance = popNode(.RetroactiveConformance) {
            if RetroactiveConformances == nil {
                RetroactiveConformances = createNode(.TypeList)
            }
            RetroactiveConformances.addChild(RetroactiveConformance)
        }
        RetroactiveConformances.reverseChildren()
        
        while true {
            let TList = createNode(.TypeList)
            TypeListList.push_back(TList)
            while let Ty = popNode(.Type) {
                TList.addChild(Ty)
            }
            TList.reverseChildren()
            
            if popNode(.EmptyList).hasValue {
                break
            }
            if popNode(.FirstElementMarker) == nil {
                return false
            }
        }
        return true
    }
    func demangleBoundGenericType() -> Node? {
        var RetroactiveConformances: Node?
        var TypeListList: [Node] = []
        
        guard demangleBoundGenerics(&TypeListList, &RetroactiveConformances) else {
            return nil
        }
        guard let Nominal = popTypeAndGetAnyGeneric() else {
            return nil
        }
        guard let BoundNode = demangleBoundGenericArgs(Nominal, &TypeListList, 0) else {
            return nil
        }
        addChild(BoundNode, RetroactiveConformances)
        let NTy = createType(BoundNode)
        addSubstitution(NTy)
        return NTy
    }
    
    func demangleBoundGenericArgs(_ Nominal: Node?, _ TypeLists: inout [Node], _ TypeListIdx: Int) -> Node? {
        // TODO: This would be a lot easier if we represented bound generic args
        // flatly in the demangling tree, since that's how they're mangled and also
        // how the runtime generally wants to consume them.
        
        guard let Nominal = Nominal else { return nil }
        guard TypeListIdx < TypeLists.count else { return nil }
        
        // Associate a context symbolic reference with all remaining generic
        // arguments.
        if Nominal.getKind() == .TypeSymbolicReference || Nominal.getKind() == .ProtocolSymbolicReference {
            let remainingTypeList = createNode(.TypeList)
            for list in TypeLists.reversed() {
                for child in list.copyOfChildren {
                    remainingTypeList.addChild(child)
                }
            }
            return createWithChildren(.BoundGenericOtherNominalType, createType(Nominal), remainingTypeList)
        }
        
        // Generic arguments for the outermost type come first.
        guard Nominal.numberOfChildren > 0 else { return nil }
        let Context = Nominal.getFirstChild()
        
        let consumesGenericArgs = nodeConsumesGenericArgs(Nominal)
        
        let args = TypeLists[TypeListIdx]
        
        var TypeListIdx = TypeListIdx
        if consumesGenericArgs {
            ++TypeListIdx
        }
        
        var nominal = Nominal
        if TypeListIdx < TypeLists.size() {
            var BoundParent: Node?
            if Context.getKind() == .Extension {
                BoundParent = demangleBoundGenericArgs(Context.getChild(1), &TypeLists, TypeListIdx)
                BoundParent = createWithChildren(.Extension, Context.getFirstChild(), BoundParent)
                if Context.getNumChildren() == 3 {
                    // Add the generic signature of the extension context.
                    addChild(BoundParent, Context.getChild(2))
                }
            } else {
                BoundParent = demangleBoundGenericArgs(Context, &TypeLists, TypeListIdx)
            }
            // Rebuild this type with the new parent type, which may have
            // had its generic arguments applied.
            guard let NewNominal = createWithChild(nominal.getKind(), BoundParent) else { return nil }
            
            // Append remaining children of the origin nominal.
            for child in nominal.copyOfChildren.dropFirst() {
                addChild(NewNominal, child)
            }
            nominal = NewNominal
        }
        if !consumesGenericArgs {
            return nominal
        }
        
        // If there were no arguments at this level there is nothing left
        // to do.
        if args.getNumChildren() == 0 {
            return nominal
        }
        
        let kind: Node.Kind
        switch nominal.getKind() {
        case .Class:
            kind = .BoundGenericClass
        case .Structure:
            kind = .BoundGenericStructure
        case .Enum:
            kind = .BoundGenericEnum
        case .Protocol:
            kind = .BoundGenericProtocol
        case .OtherNominalType:
            kind = .BoundGenericOtherNominalType
        case .TypeAlias:
            kind = .BoundGenericTypeAlias
        case .Function, .Constructor:
            // Well, not really a nominal type.
            return createWithChildren(.BoundGenericFunction, nominal, args)
        default:
            return nil
        }
        return createWithChildren(kind, createType(nominal), args)
    }
}
