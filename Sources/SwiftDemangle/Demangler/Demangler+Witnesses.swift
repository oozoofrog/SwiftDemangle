//
//  Demangler+Witnesses.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleWitness() -> Node? {
        let c = nextChar()
        switch c {
        case "C":
            return createWithChild(.EnumCase, popNode(isEntity))
        case "V":
            return createWithChild(.ValueWitnessTable, popNode(.Type))
        case "v":
            let Directness: Node.Directness
            switch nextChar() {
            case "d":
                Directness = .direct
            case "i":
                Directness = .indirect
            default:
                return nil
            }
            return createWithChildren(.FieldOffset, createNode(.Directness, Directness), popNode(isEntity))
        case "S":
            return createWithChild(.ProtocolSelfConformanceWitnessTable, popProtocol())
        case "P":
            return createWithChild(.ProtocolWitnessTable, popProtocolConformance())
        case "p":
            return createWithChild(.ProtocolWitnessTablePattern, popProtocolConformance())
        case "G":
            return createWithChild(.GenericProtocolWitnessTable, popProtocolConformance())
        case "I":
            return createWithChild(.GenericProtocolWitnessTableInstantiationFunction, popProtocolConformance())
        case "r":
            return createWithChild(.ResilientProtocolWitnessTable, popProtocolConformance())
        case "l":
            let Conf = popProtocolConformance()
            let Type = popNode(.Type)
            return createWithChildren(.LazyProtocolWitnessTableAccessor, Type, Conf)
        case "L":
            let Conf = popProtocolConformance()
            let Type = popNode(.Type)
            return createWithChildren(.LazyProtocolWitnessTableCacheVariable, Type, Conf)
        case "a":
            return createWithChild(.ProtocolWitnessTableAccessor, popProtocolConformance())
        case "t":
            let Name = popNode(isDeclName)
            let Conf = popProtocolConformance()
            return createWithChildren(.AssociatedTypeMetadataAccessor, Conf, Name)
        case "T":
            let ProtoTy = popNode(.Type)
            let ConformingType = popAssocTypePath()
            let Conf = popProtocolConformance()
            return createWithChildren(.AssociatedTypeWitnessTableAccessor, Conf, ConformingType, ProtoTy)
        case "b":
            let ProtoTy = popNode(.Type)
            let Conf = popProtocolConformance()
            return createWithChildren(.BaseWitnessTableAccessor, Conf, ProtoTy)
        case "O":
            switch nextChar() {
            case "B":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedInitializeWithTakeNoValueWitness, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedInitializeWithTakeNoValueWitness, popNode(.Type))
            case "C":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedInitializeWithCopyNoValueWitness, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedInitializeWithCopyNoValueWitness, popNode(.Type))
            case "D":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedAssignWithTakeNoValueWitness, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedAssignWithTakeNoValueWitness, popNode(.Type))
            case "F":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedAssignWithCopyNoValueWitness, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedAssignWithCopyNoValueWitness, popNode(.Type))
            case "H":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedDestroyNoValueWitness, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedDestroyNoValueWitness, popNode(.Type))
            case "y":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedCopy, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedCopy, popNode(.Type))
            case "e":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedConsume, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedConsume, popNode(.Type))
            case "r":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedRetain, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedRetain, popNode(.Type))
            case "s":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedRelease, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedRelease, popNode(.Type))
            case "b":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedInitializeWithTake, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedInitializeWithTake, popNode(.Type))
            case "c":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedInitializeWithCopy, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedInitializeWithCopy, popNode(.Type))
            case "d":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedAssignWithTake, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedAssignWithTake, popNode(.Type))
            case "f":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedAssignWithCopy, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedAssignWithCopy, popNode(.Type))
            case "h":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedDestroy, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedDestroy, popNode(.Type))
            case "g":
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedEnumGetTag, popNode(.Type), sig)
                }
                return createWithChild(.OutlinedEnumGetTag, popNode(.Type))
            case "i":
                let enumCaseIdx = demangleIndexAsNode()
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedEnumTagStore, popNode(.Type), sig,
                                    enumCaseIdx)
                }
                return createWithChildren(.OutlinedEnumTagStore, popNode(.Type), enumCaseIdx)
            case "j":
                let enumCaseIdx = demangleIndexAsNode()
                if let sig = popNode(.DependentGenericSignature) {
                    return createWithChildren(.OutlinedEnumProjectDataForLoad, popNode(.Type), sig,
                                    enumCaseIdx)
                }
                return createWithChildren(.OutlinedEnumProjectDataForLoad, popNode(.Type), enumCaseIdx)
            default:
                return nil
            }
        case "Z", "z":
            let declList = createNode(.GlobalVariableOnceDeclList)
            var vars: [Node] = []
            while popNode(.FirstElementMarker).hasValue {
                guard let identifier = popNode(isDeclName) else { return nil }
                vars.append(identifier)
            }
            for node in vars {
                declList.addChild(node)
            }
            
            guard let context = popContext() else { return nil }
            let kind: Node.Kind = c == "Z" ? .GlobalVariableOnceFunction : .GlobalVariableOnceToken
            return createWithChildren(kind, context, declList)
        case "J":
            return demangleDifferentiabilityWitness()
        default:
            return nil
        }
    }
    
    func demangleSpecialType() -> Node? {
        let specialChar = nextChar()
        switch specialChar {
        case "E":
            return popFunctionType(.NoEscapeFunctionType)
        case "A":
            return popFunctionType(.EscapingAutoClosureType)
        case "f":
            return popFunctionType(.ThinFunctionType)
        case "K":
            return popFunctionType(.AutoClosureType)
        case "U":
            return popFunctionType(.UncurriedFunctionType)
        case "L":
            return popFunctionType(.EscapingObjCBlock)
        case "B":
            return popFunctionType(.ObjCBlock)
        case "C":
            return popFunctionType(.CFunctionPointer)
        case "z":
            let cchar = nextChar()
            switch cchar {
            case "B":
                return popFunctionType(.ObjCBlock, true)
            case "C":
                return popFunctionType(.CFunctionPointer, true)
            default:
                return nil
            }
        case "o":
            return createType(createWithChild(.Unowned, popNode(.Type)))
        case "u":
            return createType(createWithChild(.Unmanaged, popNode(.Type)))
        case "w":
            return createType(createWithChild(.Weak, popNode(.Type)))
        case "b":
            return createType(createWithChild(.SILBoxType, popNode(.Type)))
        case "D":
            return createType(createWithChild(.DynamicSelf, popNode(.Type)))
        case "M":
            let MTR = demangleMetatypeRepresentation()
            let Type = popNode(.Type)
            return createType(createWithChildren(.Metatype, MTR, Type))
        case "m":
            let MTR = demangleMetatypeRepresentation()
            let Type = popNode(.Type)
            return createType(createWithChildren(.ExistentialMetatype, MTR, Type))
        case "p":
            return createType(createWithChild(.ExistentialMetatype, popNode(.Type)))
        case "P":
            let Reqs = demangleConstrainedExistentialRequirementList()
            let Base = popNode(.Type)
            return createType(createWithChildren(.ConstrainedExistential, Base, Reqs))
        case "c":
            let Superclass = popNode(.Type)
            let Protocols = demangleProtocolList()
            return createType(createWithChildren(.ProtocolListWithClass, Protocols, Superclass))
        case "l":
            let Protocols = demangleProtocolList()
            return createType(createWithChild(.ProtocolListWithAnyObject, Protocols))
        case "X", "x":
            // SIL box types.
            var signature: Node?
            var genericArgs: Node?
            if specialChar == "X" {
                signature = popNode(.DependentGenericSignature)
                if signature == nil {
                    return nil
                }
                genericArgs = popTypeList()
                if genericArgs == nil {
                    return nil
                }
            }
            
            guard let fieldTypes = popTypeList() else { return nil }
            // Build layout.
            let layout = createNode(.SILBoxLayout)
            for i in 0..<fieldTypes.numberOfChildren {
                var fieldType: Node? = fieldTypes.getChild(i)
                assert(fieldType?.getKind() == .Type)
                var isMutable = false
                // 'inout' typelist mangling is used to represent mutable fields.
                if fieldType?.getChild(0).getKind() == .InOut {
                    isMutable = true
                    fieldType = createType(fieldType?.getChild(0).getChild(0))
                }
                let field = createNode(isMutable ? .SILBoxMutableField : .SILBoxImmutableField)
                field.addChild(fieldType)
                layout.addChild(field)
            }
            let boxTy = createNode(.SILBoxTypeWithLayout)
            boxTy.addChild(layout)
            if signature.hasValue {
                boxTy.addChild(signature)
                assert(genericArgs.hasValue)
                boxTy.addChild(genericArgs)
            }
            return createType(boxTy)
        case "Y":
            return demangleAnyGenericType(.OtherNominalType)
        case "Z":
            let types = popTypeList()
            let name = popNode(.Identifier)
            let parent = popContext()
            var anon: Node? = createNode(.AnonymousContext)
            anon = addChild(anon, name)
            anon = addChild(anon, parent)
            anon = addChild(anon, types)
            return anon
        case "e":
            return createType(createNode(.ErrorType))
        case "S":
            // Sugared type for debugger.
            switch nextChar() {
            case "q":
                return createType(createWithChild(.SugaredOptional, popNode(.Type)))
            case "a":
                return createType(createWithChild(.SugaredArray, popNode(.Type)))
            case "D":
                let value = popNode(.Type)
                let key = popNode(.Type)
                return createType(createWithChildren(.SugaredDictionary, key, value))
            case "p":
                return createType(createWithChild(.SugaredParen, popNode(.Type)))
            case "A":
                let element = popNode(.Type)
                let count = popNode(.Type)
                return createType(createWithChildren(.SugaredInlineArray, count, element))
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
    func demangleMetatypeRepresentation() -> Node? {
        switch nextChar() {
        case "t":
            return createNode(.MetatypeRepresentation, "@thin")
        case "T":
            return createNode(.MetatypeRepresentation, "@thick")
        case "o":
            return createNode(.MetatypeRepresentation, "@objc_metatype")
        default:
            return nil
        }
    }
    
    func demangleValueWitness() -> Node? {
        var Code = ""
        Code.append(nextChar())
        Code.append(nextChar())
        guard let kind = decodeValueWitnessKind(Code) else { return nil }
        let VW = createNode(.ValueWitness)
        addChild(VW, createNode(.Index, kind))
        return addChild(VW, popNode(.Type))
    }
    
    func decodeValueWitnessKind(_ CodeStr: String) -> Node.ValueWitnessKind? {
        return Node.ValueWitnessKind(code: CodeStr)
    }
}
