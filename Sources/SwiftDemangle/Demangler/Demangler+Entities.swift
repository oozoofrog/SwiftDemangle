//
//  Demangler+Entities.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleAccessor(_ ChildNode: Node?) -> Node? {
        let Kind: Node.Kind
        switch nextChar() {
        case "m":
            Kind = .MaterializeForSet
        case "s":
            Kind = .Setter
        case "g":
            Kind = .Getter
        case "G":
            Kind = .GlobalGetter
        case "w":
            Kind = .WillSet
        case "W":
            Kind = .DidSet
        case "r":
            Kind = .ReadAccessor
        case "y":
            Kind = .YieldingBorrowAccessor
        case "M":
            Kind = .ModifyAccessor
        case "x":
            Kind = .YieldingMutateAccessor
        case "i":
            Kind = .InitAccessor
        case "b":
            Kind = .BorrowAccessor
        case "z":
            Kind = .MutateAccessor
        case "a":
            switch nextChar() {
            case "O":
                Kind = .OwningMutableAddressor
            case "o":
                Kind = .NativeOwningMutableAddressor
            case "P":
                Kind = .NativePinningMutableAddressor
            case "u":
                Kind = .UnsafeMutableAddressor
            default:
                return nil
            }
        case "l":
            switch nextChar() {
            case "O":
                Kind = .OwningAddressor
            case "o":
                Kind = .NativeOwningAddressor
            case "p":
                Kind = .NativePinningAddressor
            case "u":
                Kind = .UnsafeAddressor
            default:
                return nil
            }
        case "p": // Pseudo-accessor referring to the variable/subscript itself
            return ChildNode
        default:
            return nil
        }
        let Entity = createWithChild(Kind, ChildNode)
        return Entity
    }
    
    enum Args {
        case None, TypeAndMaybePrivateName, TypeAndIndex, Index, ContextArg
    }
    
    func demangleFunctionEntity() -> Node? {
        let Args: Args
        
        var Kind = Node.Kind.EmptyList
        switch nextChar() {
        case "D":
            Args = .None
            Kind = .Deallocator
        case "d":
            Args = .None
            Kind = .Destructor
        case "Z":
            Args = .None
            Kind = .IsolatedDeallocator
        case "E":
            Args = .None
            Kind = .IVarDestroyer
        case "e":
            Args = .None
            Kind = .IVarInitializer
        case "i":
            Args = .None
            Kind = .Initializer
        case "C":
            Args = .TypeAndMaybePrivateName
            Kind = .Allocator
        case "c":
            Args = .TypeAndMaybePrivateName
            Kind = .Constructor
        case "U":
            Args = .TypeAndIndex
            Kind = .ExplicitClosure
        case "u":
            Args = .TypeAndIndex
            Kind = .ImplicitClosure
        case "A":
            Args = .Index
            Kind = .DefaultArgumentInitializer
        case "m":
            return demangleEntity(.Macro)
        case "M":
            return demangleMacroExpansion()
        case "p":
            return demangleEntity(.GenericTypeParamDecl)
        case "P":
            Args = .None
            Kind = .PropertyWrapperBackingInitializer
        case "F":
            Args = .None
            Kind = .PropertyWrappedFieldInitAccessor
        case "W":
            Args = .None
            Kind = .PropertyWrapperInitFromProjectedValue
            break
        default:
            return nil
        }
        
        var NameOrIndex: Node?
        var ParamType: Node?
        var LabelList: Node?
        var Context: Node?
        switch Args {
        case .None:
            break
        case .TypeAndMaybePrivateName:
            NameOrIndex = popNode(.PrivateDeclName)
            ParamType = popNode(.Type)
            LabelList = popFunctionParamLabels(ParamType)
        case .TypeAndIndex:
            NameOrIndex = demangleIndexAsNode()
            ParamType = popNode(.Type)
        case .Index:
            NameOrIndex = demangleIndexAsNode()
        case .ContextArg:
            Context = popNode()
        }
        
        var Entity: Node? = createWithChild(Kind, popContext())
        switch Args {
        case .None:
            break
        case .Index:
            Entity = addChild(Entity, NameOrIndex)
        case .TypeAndMaybePrivateName:
            addChild(Entity, LabelList)
            Entity = addChild(Entity, ParamType)
            addChild(Entity, NameOrIndex)
        case .TypeAndIndex:
            Entity = addChild(Entity, NameOrIndex)
            Entity = addChild(Entity, ParamType)
        case .ContextArg:
            Entity = addChild(Entity, Context)
        }
        return Entity
    }
    
    func demangleEntity(_ kind: Node.Kind) -> Node? {
        let Type = popNode(.Type)
        let LabelList = popFunctionParamLabels(Type)
        let Name = popNode(isDeclName)
        let Context = popContext()
        return LabelList.hasValue ? createWithChildren(kind, Context, Name, LabelList, Type) : createWithChildren(kind, Context, Name, Type)
    }
    
    func demangleVariable() -> Node? {
        let Variable = demangleEntity(.Variable)
        return demangleAccessor(Variable)
    }
    
    func demangleSubscript() -> Node? {
        let PrivateName = popNode(.PrivateDeclName)
        let Type = popNode(.Type)
        let LabelList = popFunctionParamLabels(Type)
        let Context = popContext()
        
        var Subscript: Node? = createNode(.Subscript)
        Subscript = addChild(Subscript, Context)
        addChild(Subscript, LabelList)
        Subscript = addChild(Subscript, Type)
        addChild(Subscript, PrivateName)
        
        return demangleAccessor(Subscript)
    }
    
    func demangleProtocolList() -> Node? {
        let TypeList = createNode(.TypeList)
        let ProtoList = createWithChild(.ProtocolList, TypeList)
        if !popNode(.EmptyList) {
            var firstElem = false
            repeat {
                firstElem = popNode(.FirstElementMarker).hasValue
                guard let Proto = popProtocol() else { return nil }
                TypeList.addChild(Proto)
            } while !firstElem
            
            TypeList.reverseChildren()
            // TypeList grew after it was attached.
            ProtoList?.recomputeHeight()
        }
        return ProtoList
    }
    
    func demangleProtocolListType() -> Node? {
        let ProtoList = demangleProtocolList()
        return createType(ProtoList)
    }
    
    func demangleConstrainedExistentialRequirementList() -> Node? {
        let ReqList = createNode(.ConstrainedExistentialRequirementList)
        var firstElem = false
        repeat {
            firstElem = popNode(.FirstElementMarker) != nil
            guard let Req = popNode(isRequirement) else {
                return nil
            }
            ReqList.add(Req)
        } while firstElem == false
        
        ReqList.reverseChildren()
        return ReqList
    }
}
