//
//  OldDemangler+Types.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    func demangleTuple(_ isV: Node.IsVariadic) -> Node? {
        let tuple = Node(kind: .Tuple)
        var elt: Node = Node(kind: .EmptyList)
        while !nextIf("_") {
            guard isNotEmpty else { return nil }
            elt = Node(kind: .TupleElement)
            
            if isStartOfIdentifier(peekChar()) {
                guard let label = demangleIdentifier(kind: .TupleElementName) else { return nil }
                elt.add(label)
            }
            
            guard let type = demangleType() else { return nil }
            elt.add(type)
            
            tuple.add(elt)
        }
        if isV == .yes, tuple.numberOfChildren > 0 {
            elt.reverseChildren()
            let marker = Node(kind: .VariadicMarker)
            elt.add(marker)
            elt.reverseChildren()
            tuple.replaceLast(elt)
        }
        return tuple
    }
    
    func postProcessReturnTypeNode(_ out_args: Node) -> Node {
        let out_node = Node(kind: .ReturnType)
        out_node.add(out_args)
        return out_node
    }
    
    func demangleType() -> Node? {
        guard let type = demangleTypeImpl(), type.height < Node.maxDepth else { return nil }
        let nodeType = Node(kind: .Type)
        nodeType.add(type)
        return nodeType
    }
    
    func demangleFunctionType(kind: Node.Kind) -> Node? {
        var isThrows = false
        var isConcurrent = false
        var isAsync = false
        var diffKind = MangledDifferentiabilityKind.nonDifferentiable
        var globalActorType: Node?
        if isNotEmpty {
            isThrows = nextIf("z")
            isConcurrent = nextIf("y")
            isAsync = nextIf("Z")
            
            if nextIf("D") {
                let kind = MangledDifferentiabilityKind(rawValue: nextChar().description) ?? .nonDifferentiable
                switch kind {
                case .forward, .reverse, .normal, .linear:
                    diffKind = kind
                case .nonDifferentiable:
                    // Any other character; OldDemangler.cpp leaves the function non-differentiable.
                    break
                }
            }
            if nextIf("Y") {
                globalActorType = demangleType()
                if globalActorType == nil {
                    return nil
                }
            }
        }
        
        guard let in_args = demangleType() else { return nil }
        guard let out_args = demangleType() else { return nil }
        let block = Node(kind: kind)
        
        if isThrows {
            block.add(.ThrowsAnnotation)
        }
        if isAsync {
            block.add(.AsyncAnnotation)
        }
        if isConcurrent {
            block.add(.ConcurrentFunctionType)
        }
        if diffKind != .nonDifferentiable {
            block.add(Node(kind: .DifferentiableFunctionType, payload: .mangledDifferentiabilityKind(diffKind)))
        }
        
        if let globalActorType = globalActorType {
            let globalActorNode = Node(kind: .GlobalActorFunctionType)
            globalActorNode.add(globalActorType)
            block.add(globalActorNode)
        }
        
        let in_node = Node(kind: .ArgumentTuple)
        in_node.add(in_args)
        block.add(in_node)
        block.add(postProcessReturnTypeNode(out_args))
        return block
    }
    
    func demangleTypeImpl() -> Node? {
        depth += 1
        defer { depth -= 1 }
        guard depth <= maxDepth else { return nil }
        guard isNotEmpty else { return nil }
        let c = nextChar()
        if c == "B" {
            guard isNotEmpty else { return nil }
            let c = nextChar()
            if c == "b" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.BridgeObject")
            }
            if c == "B" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.UnsafeValueBuffer")
            }
            if c == "f" {
                var size: Node.IndexType = .zero
                if demangleBuiltinSize(number: &size) {
                    return Node(kind: .BuiltinTypeName, text: "Builtin.FPIEEE\(size)")
                }
            }
            if c == "i" {
                var size: Node.IndexType = .zero
                if demangleBuiltinSize(number: &size) {
                    return Node(kind: .BuiltinTypeName, text: "Builtin.Int\(size)")
                }
            }
            if c == "v" {
                var elts: Node.IndexType = .zero
                if demangleNatural(number: &elts) {
                    guard nextIf("B") else { return nil }
                    if nextIf("i") {
                        var size: Node.IndexType = .zero
                        guard demangleBuiltinSize(number: &size) else { return nil }
                        return Node(kind: .BuiltinTypeName, text: "Builtin.Vec\(elts)xInt\(size)")
                    }
                    if nextIf("f") {
                        var size: Node.IndexType = .zero
                        guard demangleBuiltinSize(number: &size) else { return nil }
                        return Node(kind: .BuiltinTypeName, text: "Builtin.Vec\(elts)xFPIEEE\(size)")
                    }
                    if nextIf("p") {
                        return Node(kind: .BuiltinTypeName, text: "Builtin.Vec\(elts)xRawPointer")
                    }
                }
            }
            if c == "O" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.UnknownObject")
            }
            if c == "o" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.NativeObject")
            }
            if c == "p" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.RawPointer")
            }
            if c == "t" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.SILToken")
            }
            if c == "w" {
                return Node(kind: .BuiltinTypeName, text: "Builtin.Word")
            }
            return nil
        }
        if c == "a" {
            return demangleDeclarationName(kind: .TypeAlias)
        }
        
        if c == "b" {
            return demangleFunctionType(kind: .ObjCBlock)
        }
        if c == "c" {
            return demangleFunctionType(kind: .CFunctionPointer)
        }
        if c == "D" {
            guard let type = demangleType() else { return nil }
            let dynamicSelf = Node(kind: .DynamicSelf)
            dynamicSelf.add(type)
            return dynamicSelf
        }
        if c == "E" {
            guard nextIf("RR") else { return nil }
            return Node(kind: .ErrorType)
        }
        if c == "F" {
            return demangleFunctionType(kind: .FunctionType)
        }
        if c == "f" {
            return demangleFunctionType(kind: .UncurriedFunctionType)
        }
        if c == "G" {
            return demangleBoundGenericType()
        }
        if c == "X" {
            if nextIf("b") {
                guard let type = demangleType() else { return nil }
                let boxType = Node(kind: .SILBoxType)
                boxType.add(type)
                return boxType
            }
            if nextIf("B") {
                var signature: Node?
                if nextIf("G") {
                    signature = demangleGenericSignature(isPseudogeneric: false)
                    if signature == nil {
                        return nil
                    }
                }
                let layout = Node(kind: .SILBoxLayout)
                while !nextIf("_") {
                    var kind: Node.Kind
                    if nextIf("m") {
                        kind = .SILBoxMutableField
                    } else if nextIf("i") {
                        kind = .SILBoxImmutableField
                    } else {
                        return nil
                    }
                    
                    guard let type = demangleType() else { return nil }
                    let field = Node(kind: kind)
                    field.add(type)
                    layout.add(field)
                }
                var genericArgs: Node?
                if signature != nil {
                    genericArgs = Node(kind: .TypeList)
                    while !nextIf("_") {
                        guard let type = demangleType() else { return nil }
                        genericArgs?.add(type)
                    }
                }
                let boxType = Node(kind: .SILBoxTypeWithLayout)
                boxType.add(layout)
                if let signature = signature {
                    boxType.add(signature)
                    assert(genericArgs != nil)
                    boxType.add(genericArgs)
                }
                return boxType
            }
        }
        if c == "K" {
            return demangleFunctionType(kind: .AutoClosureType)
        }
        if c == "M" {
            guard let type = demangleType() else { return nil }
            let metatype = Node(kind: .Metatype)
            metatype.add(type)
            return metatype
        }
        if c == "X" {
            if nextIf("M") {
                guard let metatypeRepr = demangleMetatypeRepresentation() else { return nil }
                
                guard let type = demangleType() else { return nil }
                let metatype = Node(kind: .Metatype)
                metatype.add(metatypeRepr)
                metatype.add(type)
                return metatype
            }
        }
        if c == "P" {
            if nextIf("M") {
                guard let type = demangleType() else { return nil }
                let metatype = Node(kind: .ExistentialMetatype)
                metatype.add(type)
                return metatype
            }
            
            return demangleProtocolList()
        }
        
        if c == "X" {
            if nextIf("P") {
                if nextIf("M") {
                    guard let metatypeRepr = demangleMetatypeRepresentation() else { return nil }
                    
                    guard let type = demangleType() else { return nil }
                    
                    let metatype = Node(kind: .ExistentialMetatype)
                    metatype.add(metatypeRepr)
                    metatype.add(type)
                    return metatype
                }
                
                return demangleProtocolList()
            }
        }
        if c == "Q" {
            if nextIf("u") {
                // Special mangling for opaque return type.
                return Node(kind: .OpaqueReturnType)
            }
            return demangleArchetypeType()
        }
        if c == "q" {
            return demangleDependentType()
        }
        if c == "x" {
            // Special mangling for the first generic param.
            return getDependentGenericParamType(depth: 0, index: 0)
        }
        if c == "w" {
            return demangleAssociatedTypeSimple()
        }
        if c == "W" {
            return demangleAssociatedTypeCompound()
        }
        if c == "R" {
            let in_out = Node(kind: .InOut)
            guard  let type = demangleTypeImpl() else { return nil }
            in_out.add(type)
            return in_out
        }
        if c == "k" {
            let noDerivative = Node(kind: .NoDerivative)
            guard let type = demangleTypeImpl() else { return nil }
            noDerivative.add(type)
            return noDerivative
        }
        if c == "S" {
            return demangleSubstitutionIndex()
        }
        if c == "T" {
            return demangleTuple(.no)
        }
        if c == "t" {
            return demangleTuple(.yes)
        }
        if c == "u" {
            guard let sig = demangleGenericSignature() else { return nil }
            guard let sub = demangleType() else { return nil }
            let dependentGenericType = Node(kind: .DependentGenericType)
            dependentGenericType.add(sig)
            dependentGenericType.add(sub)
            return dependentGenericType
        }
        if c == "X" {
            if nextIf("f") {
                return demangleFunctionType(kind: .ThinFunctionType)
            }
            if nextIf("o") {
                guard let type = demangleType() else { return nil }
                let unowned = Node(kind: .Unowned)
                unowned.add(type)
                return unowned
            }
            if nextIf("u") {
                guard let type = demangleType() else { return nil }
                let unowned = Node(kind: .Unmanaged)
                unowned.add(type)
                return unowned
            }
            if nextIf("w") {
                guard let type = demangleType() else { return nil }
                let weak = Node(kind: .Weak)
                weak.add(type)
                return weak
            }
            
            // type ::= 'XF' impl-function-type
            if nextIf("F") {
                return demangleImplFunctionType()
            }
            
            return nil
        }
        guard isStartOfNominalType(c) else { return nil }
        return demangleDeclarationName(kind: nominalTypeMarkerToNodeKind(c))
    }
    
    func demangleReabstractSignature(signature: inout Node) -> Bool {
        if nextIf("G") {
            guard let generics = demangleGenericSignature() else { return false }
            signature.add(generics)
        }
        
        guard let srcType = demangleType() else { return false }
        signature.add(srcType)
        
        guard let destType = demangleType() else { return false }
        signature.add(destType)
        
        return true
    }
}
