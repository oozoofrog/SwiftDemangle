//
//  Demangler+Types.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleMetatype() -> Node? {
        switch nextChar() {
        case "a":
            return createWithPoppedType(.TypeMetadataAccessFunction)
        case "A":
            return createWithChild(.ReflectionMetadataAssocTypeDescriptor, popProtocolConformance())
        case "b":
            return createWithPoppedType(.CanonicalSpecializedGenericTypeMetadataAccessFunction)
        case "B":
            return createWithChild(.ReflectionMetadataBuiltinDescriptor, popNode(.Type))
        case "c":
            return createWithChild(.ProtocolConformanceDescriptor, popProtocolConformance())
        case "C":
            guard let Ty = popNode(.Type), Ty.getChild(0).getKind().isAnyGeneric else { return nil }
            return createWithChild(.ReflectionMetadataSuperclassDescriptor, Ty.getChild(0))
        case "D":
            return createWithPoppedType(.TypeMetadataDemanglingCache)
        case "f":
            return createWithPoppedType(.FullTypeMetadata)
        case "F":
            return createWithChild(.ReflectionMetadataFieldDescriptor, popNode(.Type))
        case "g":
            return createWithChild(.OpaqueTypeDescriptorAccessor, popNode())
        case "h":
            return createWithChild(.OpaqueTypeDescriptorAccessorImpl, popNode())
        case "i":
            return createWithPoppedType(.TypeMetadataInstantiationFunction)
        case "I":
            return createWithPoppedType(.TypeMetadataInstantiationCache)
        case "j":
            return createWithChild(.OpaqueTypeDescriptorAccessorKey, popNode())
        case "J":
            return createWithChild(.NoncanonicalSpecializedGenericTypeMetadataCache, popNode())
        case "k":
            return createWithChild(.OpaqueTypeDescriptorAccessorVar, popNode())
        case "K":
            return createWithChild(.MetadataInstantiationCache, popNode())
        case "l":
            return createWithPoppedType(.TypeMetadataSingletonInitializationCache)
        case "L":
            return createWithPoppedType(.TypeMetadataLazyCache)
        case "m":
            return createWithPoppedType(.Metaclass)
        case "M":
            return createWithPoppedType(.CanonicalSpecializedGenericMetaclass)
        case "n":
            return createWithPoppedType(.NominalTypeDescriptor)
        case "N":
            return createWithPoppedType(.NoncanonicalSpecializedGenericTypeMetadata)
        case "o":
            return createWithPoppedType(.ClassMetadataBaseOffset)
        case "p":
            return createWithChild(.ProtocolDescriptor, popProtocol())
        case "P":
            return createWithPoppedType(.GenericTypeMetadataPattern)
        case "Q":
            return createWithChild(.OpaqueTypeDescriptor, popNode())
        case "r":
            return createWithPoppedType(.TypeMetadataCompletionFunction)
        case "s":
            return createWithPoppedType(.ObjCResilientClassStub)
        case "S":
            return createWithChild(.ProtocolSelfConformanceDescriptor, popProtocol())
        case "t":
            return createWithPoppedType(.FullObjCResilientClassStub)
        case "u":
            return createWithPoppedType(.MethodLookupFunction)
        case "U":
            return createWithPoppedType(.ObjCMetadataUpdateFunction)
        case "V":
            return createWithChild(.PropertyDescriptor, popNode(isEntity))
        case "X":
            return demanglePrivateContextDescriptor()
        case "z":
            return createWithPoppedType(.CanonicalPrespecializedGenericTypeCachingOnceToken)
        default:
            return nil
        }
    }
    
    func demanglePrivateContextDescriptor() -> Node? {
        switch nextChar() {
        case "E":
            guard let Extension = popContext() else { return nil }
            return createWithChild(.ExtensionDescriptor, Extension)
        case "M":
            guard let Module = popModule() else { return nil }
            return createWithChild(.ModuleDescriptor, Module)
        case "Y":
            guard let Discriminator = popNode() else { return nil }
            guard let Context = popContext() else { return nil }
            
            let node = createNode(.AnonymousDescriptor)
            node.addChild(Context)
            node.addChild(Discriminator)
            return node
        case "X":
            guard let Context = popContext() else { return nil }
            return createWithChild(.AnonymousDescriptor, Context)
        case "A":
            guard let path = popAssocTypePath() else { return nil }
            guard let base = popNode(.Type) else { return nil }
            return createWithChildren(.AssociatedTypeGenericParamRef, base, path)
        default:
            return nil
        }
    }
    
    func demangleArchetype() -> Node? {
        switch nextChar() {
        case "a":
            let Ident = popNode(.Identifier)
            let ArcheTy = popTypeAndGetChild()
            let AssocTy = createType(createWithChildren(.AssociatedTypeRef, ArcheTy, Ident))
            addSubstitution(AssocTy)
            return AssocTy
        case "O":
            let definingContext = popContext()
            return createWithChild(.OpaqueReturnTypeOf, definingContext)
        case "o":
            let index = demangleIndex()
            var boundGenericArgs: [Node] = []
            var retroactiveConformances: Node?
            if !demangleBoundGenerics(&boundGenericArgs, &retroactiveConformances) {
                return nil
            }
            guard let Name = popNode() else { return nil }
            let opaque = createWithChildren(.OpaqueType, Name, createNode(.Index, index))
            let boundGenerics = createNode(.TypeList)
            for node in boundGenericArgs.reversed() {
                boundGenerics.addChild(node)
            }
            opaque.addChild(boundGenerics)
            if let retroactiveConformances = retroactiveConformances {
                opaque.addChild(retroactiveConformances)
            }
            
            let opaqueTy = createType(opaque)
            addSubstitution(opaqueTy)
            return opaqueTy
        case "r":
            return createType(createNode(.OpaqueReturnType))
        case "x":
            let T = demangleAssociatedTypeSimple()
            addSubstitution(T)
            return T
        case "X":
            let T = demangleAssociatedTypeCompound()
            addSubstitution(T)
            return T
        case "y":
            let T = demangleAssociatedTypeSimple(demangleGenericParamIndex())
            addSubstitution(T)
            return T
        case "Y":
            let T = demangleAssociatedTypeCompound(demangleGenericParamIndex())
            addSubstitution(T)
            return T
        case "z":
            let T = demangleAssociatedTypeSimple(getDependentGenericParamType(0, 0))
            addSubstitution(T)
            return T
        case "Z":
            let T = demangleAssociatedTypeCompound(getDependentGenericParamType(0, 0))
            addSubstitution(T)
            return T
        case "p":
            let CountTy = popTypeAndGetChild()
            let PatternTy = popTypeAndGetChild()
            return createType(createWithChildren(.PackExpansion, PatternTy, CountTy))
        case "e":
            let PackTy = popTypeAndGetChild()
            let level = demangleIndex()
            if level < 0 { return nil }
            return createType(createWithChildren(.PackElement, PackTy, createNode(.PackElementLevel, level)))
        case "P":
            return popPack()
        case "S":
            return popSILPack()
        default:
            return nil
        }
    }
    
    func demangleAssociatedTypeSimple(_ Base: Node? = nil) -> Node? {
        let ATName = popAssocTypeName()
        var BaseTy: Node?
        if Base.hasValue {
            BaseTy = createType(Base)
        } else {
            BaseTy = popNode(.Type)
        }
        return createType(createWithChildren(.DependentMemberType, BaseTy, ATName))
    }
    
    func demangleAssociatedTypeCompound(_ Base: Node? = nil) -> Node? {
        var AssocTyNames: [Node] = []
        var firstElem = false
        repeat {
            firstElem = popNode(.FirstElementMarker).hasValue
            guard let AssocTyName = popAssocTypeName() else { return nil }
            AssocTyNames.push_back(AssocTyName)
        } while !firstElem
        
        var BaseTy: Node?
        if let base = Base {
            BaseTy = createType(base)
        } else {
            BaseTy = popNode(.Type)
        }
        
        while let AssocTy = AssocTyNames.popLast() {
            var depTy: Node? = createNode(.DependentMemberType)
            depTy = addChild(depTy, BaseTy)
            BaseTy = createType(addChild(depTy, AssocTy))
        }
        return BaseTy
    }
    
    func demangleGenericParamIndex() -> Node? {
        if nextIf("d") {
            let depth = demangleIndex() + 1
            let index = demangleIndex()
            return getDependentGenericParamType(depth, index)
        }
        if nextIf("z") {
            return getDependentGenericParamType(0, 0)
        }
        if nextIf("s") {
            return createNode(.ConstrainedExistentialSelf)
        }
        return getDependentGenericParamType(0, demangleIndex() + 1)
    }
    
    func demangleIntegerType() -> Node? {
        var integer: Node?

        switch (peekChar()) {
        case "n":
            nextChar()
            integer = createNode(.NegativeInteger, -demangleIndex())
        default:
            integer = createNode(.Integer, demangleIndex())
        }
        return createType(integer)
    }
}
