//
//  NodePrinter.swift
//  Demangling
//
//  Created by spacefrog on 2021/03/30.
//

import Foundation

struct NodePrinter {
    let options: DemangleOptions
    var printText: String = ""
    var isValid: Bool = true
    var isSpecializationPrefixPrinted = false
    
    mutating private func printer(_ text: String) {
        printText.append(text)
    }
    
    mutating private func printerText(_ node: Node) {
        printer(node.text)
    }
    
    mutating private func printerIndex(_ index: Int) {
        printer(index.description)
    }
    
    mutating func printRoot(_ node: Node) -> String {
        print(node)
        return printText
    }
    
    @discardableResult
    mutating func print(_ node: Node, asPrefixContext: Bool = false) -> Node? {
        let kind = node.kind
        switch kind {
        case .Static:
            printer("static ")
            print(node.children[0])
        case .CurryThunk:
            printer("curry thunk of ")
            print(node.children[0])
        case .DispatchThunk:
            printer("dispatch thunk of ")
            print(node.children[0])
        case .MethodDescriptor:
            printer("method descriptor for ")
            print(node.children[0])
        case .MethodLookupFunction:
            printer("method lookup function for ")
            print(node.children[0])
        case .ObjCMetadataUpdateFunction:
            printer("ObjC metadata update function for ")
            print(node.children[0])
        case .ObjCResilientClassStub:
            printer("ObjC resilient class stub for ")
            print(node.children[0])
        case .FullObjCResilientClassStub:
            printer("full ObjC resilient class stub for ")
            print(node.children[0])
        case .OutlinedBridgedMethod:
            printer("outlined bridged method (\(node.text)) of ")
        case .OutlinedCopy:
            printer("outlined copy of ")
            print(node.children[0])
            if node.children.count > 1 {
                print(node.children[1])
            }
        case .OutlinedConsume:
            printer("outlined consume of ")
            print(node.children[0])
            if node.children.count > 1 {
                print(node.children[1])
            }
        case .OutlinedRetain:
            printer("outlined retain of ")
            print(node.children[0])
        case .OutlinedRelease:
            printer("outlined release of ")
            print(node.children[0])
        case .OutlinedInitializeWithTake:
            printer("outlined init with take of ")
            print(node.children[0])
        case .OutlinedInitializeWithCopy:
            printer("outlined init with copy of ")
            print(node.children[0])
        case .OutlinedAssignWithTake:
            printer("outlined assign with take of ")
            print(node.children[0])
        case .OutlinedAssignWithCopy:
            printer("outlined assign with copy of ")
            print(node.children[0])
        case .OutlinedDestroy:
            printer("outlined destroy of ")
            print(node.children[0])
        case .OutlinedVariable:
            printer("outlined variable #\(node.index.or(0)) of ")
        case .Directness:
            printer("\(node.directness.text) ")
        case .AnonymousContext:
            if options.contains([.qualifyEntities, .displayExtensionContexts]) {
                print(node.children[1])
                printer(".(unknown context at ")
                print(node.children[0])
                printer(")")
                if node.children.count >= 3, node.children[2].children.count > 0 {
                    printer("<")
                    print(node.children[2])
                    printer(">")
                }
            }
        case .Extension:
            assert(node.children.count == 2 || node.children.count == 3, "Extension expects 2 or 3 children.")
            if options.contains([.qualifyEntities, .displayExtensionContexts]) {
                printer("(extension in ")
                // Print the module where extension is defined.
                print(node.children[0], asPrefixContext: true)
                printer("):")
            }
            print(node.children[1])
            if node.children.count == 3 {
                // Currently the runtime does not mangle the generic signature.
                // This is an open to-do in swift::_buildDemanglingForContext().
                if !options.contains(.printForTypeName) {
                    print(node.children[2])
                }
            }
        case .Variable:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: true)
        case .Function, .BoundGenericFunction:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: true)
        case .Subscript:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: false, extraName: "", extraIndex: -1, overwriteName: "subscript")
        case .GenericTypeParamDecl:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: true)
        case .ExplicitClosure:
            let typePrinting: TypePrinting = options.contains(.showFunctionArgumentTypes) ? .functionStyle : .noType
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: typePrinting, hasName: false, extraName: "closure #", extraIndex: Int(node.children[1].index.or(0)) + 1)
            
        case .ImplicitClosure:
            let typePrinting: TypePrinting = options.contains(.showFunctionArgumentTypes) ? .functionStyle : .noType
            return printEntity(entity: node,
                               asPrefixContext: asPrefixContext,
                               typePrinting: typePrinting,
                               hasName: false,
                               extraName: "implicit closure #",
                               extraIndex: Int(node.children[1].index.or(0)) + 1)
        case .Global:
            printChildren(node)
        case .Suffix:
            if options.contains(.displayUnmangledSuffix) {
                printer(" with unmangled suffix " + self.quoted(text: node.text))
            }
        case .Initializer:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "variable initialization expression")
        case .PropertyWrapperBackingInitializer:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "property wrapper backing initializer")
        case .DefaultArgumentInitializer:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "default argument ", extraIndex: node.children[1].index.flatMap(Int.init).or(0))
        case .DeclContext:
            print(node.children[0])
        case .Type:
            print(node.children[0])
        case .TypeMangling:
            if node.children[0].kind == .LabelList {
                printFunctionType(labelList: node.children[0], type: node.children[1].children[0])
            } else {
                print(node.children[0])
            }
        case .Class,
             .Structure,
             .Enum,
             .Protocol,
             .TypeAlias,
             .OtherNominalType:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: true)
        case .LocalDeclName:
            print(node.children[1])
            if options.contains(.displayLocalNameContexts) {
                printer(" #\(node.children[0].index.or(0) + 1)")
            }
        case .PrivateDeclName:
            if node.children.count > 1 {
                if options.contains(.showPrivateDiscriminators) {
                    printer("(")
                }
                print(node.children[1])
                
                if options.contains(.showPrivateDiscriminators) {
                    printer(" in " + node.children[0].text + ")")
                }
            } else {
                if options.contains(.showPrivateDiscriminators) {
                    printer("(in " + node.children[0].text + ")")
                }
            }
        case .RelatedEntityDeclName:
            printer("related decl '" + node.children[0].text + "' for ")
            print(node.children[1])
        case .Module:
            if options.contains(.displayModuleNames) {
                printer(node.text)
            }
        case .Identifier:
            printer(node.text)
        case .Index:
            printer(node.index.or(0).description)
        case .UnknownIndex:
            printer("unknown index")
        case .FunctionType,
             .UncurriedFunctionType,
             .NoEscapeFunctionType,
             .AutoClosureType,
             .EscapingAutoClosureType,
             .ThinFunctionType,
             .CFunctionPointer,
             .ObjCBlock,
             .EscapingObjCBlock:
            printFunctionType(type: node)
        case .ClangType:
            printer(node.text)
        case .ArgumentTuple:
            printFunctionParameters(parameterType: node, showTypes: options.contains(.showFunctionArgumentTypes))
        case .Tuple:
            printer("(")
            printChildren(node, separator: ", ")
            printer(")")
        case .TupleElement:
            if let label = node.childIf(.TupleElementName) {
                printer(label.text + ": ")
            }
            
            if let type = node.childIf(.Type) {
                print(type)
            } else {
                assertionFailure("malformed .TupleElement")
            }
            
            if node.childIf(.VariadicMarker) != nil {
                printer("...")
            }
        case .TupleElementName:
            printer(node.text + ": ")
        case .ReturnType:
            if node.children.isEmpty {
                printer(" -> " + node.text)
            } else {
                printer(" -> ")
                printChildren(node)
            }
            
        case .RetroactiveConformance:
            if node.children.count != 2 {
                return nil
            }
            
            printer("retroactive @ ")
            print(node.children[0])
            print(node.children[1])
        case .Weak:
            printer(ReferenceOwnership.weak.rawValue + " ")
            print(node.children[0])
        case .Unowned:
            printer(ReferenceOwnership.unowned.rawValue + " ")
            print(node.children[0])
        case .Unmanaged:
            printer(ReferenceOwnership.unmanaged.rawValue + " ")
            print(node.children[0])
        case .InOut:
            printer("inout ")
            print(node.children[0])
        case .Shared:
            printer("__shared ")
            print(node.children[0])
        case .Owned:
            printer("__owned ")
            print(node.children[0])
        case .NonObjCAttribute:
            printer("@nonobjc ")
        case .ObjCAttribute:
            printer("@objc ")
        case .DirectMethodReferenceAttribute:
            printer("super ")
        case .DynamicAttribute:
            printer("dynamic ")
        case .VTableAttribute:
            printer("override ")
        case .FunctionSignatureSpecialization:
            printSpecializationPrefix(node: node, description:  "function signature specialization")
        case .GenericPartialSpecialization:
            printSpecializationPrefix(node: node, description: "generic partial specialization", paramPrefix: "Signature = ")
        case .GenericPartialSpecializationNotReAbstracted:
            printSpecializationPrefix(node: node, description: "generic not-reabstracted partial specialization", paramPrefix: "Signature = ")
        case .GenericSpecialization,
             .GenericSpecializationInResilienceDomain:
            printSpecializationPrefix(node: node, description: "generic specialization")
        case .GenericSpecializationPrespecialized:
            printSpecializationPrefix(node: node, description: "generic pre-specialization")
        case .GenericSpecializationNotReAbstracted:
            printSpecializationPrefix(node: node, description: "generic not re-abstracted specialization")
        case .InlinedGenericFunction:
            printSpecializationPrefix(node: node, description: "inlined generic function")
        case .IsSerialized:
            printer("serialized")
        case .GenericSpecializationParam:
            print(node.children[0])
            for (offset, node) in node.children.enumerated() where offset > 0 {
                if offset == 1 {
                    printer(" with ")
                } else {
                    printer(" and ")
                }
                print(node)
            }
            return nil
        case .FunctionSignatureSpecializationReturn,
             .FunctionSignatureSpecializationParam:
            fatalError("should be handled in printSpecializationPrefix")
        case .FunctionSignatureSpecializationParamPayload:
            if let demangleName = node.text.demangleSymbolAsString(with: .defaultOptions).emptyToNil() {
                printer(demangleName)
            } else {
                printer(node.text)
            }
        case .FunctionSignatureSpecializationParamKind:
            if let kind = node.functionSigSpecializationParamKind {
                var printedOptionSet = false
                if kind.containOptions(.ExistentialToGeneric) {
                    printedOptionSet = true
                    printer("Existential To Protocol Constrained Generic")
                }
                if kind.containOptions(.Dead) {
                    if printedOptionSet {
                        printer(" and ")
                    }
                    printedOptionSet = true
                    printer("Dead")
                }
                if kind.containOptions(.OwnedToGuaranteed) {
                    if printedOptionSet {
                        printer(" and ")
                    }
                    printedOptionSet = true
                    printer("Owned To Guaranteed")
                }
                
                if kind.containOptions(.GuaranteedToOwned) {
                    if printedOptionSet {
                        printer(" and ")
                    }
                    printedOptionSet = true
                    printer("Guaranteed To Owned")
                }
                
                if kind.containOptions(.SROA) {
                    if printedOptionSet {
                        printer(" and ")
                    }
                    printer("Exploded")
                    return nil
                }
                
                if printedOptionSet {
                    return nil
                }
                
                if let kind = kind.kind {
                    switch kind {
                    case .BoxToValue:
                        printer("Value Promoted from Box")
                    case .BoxToStack:
                        printer("Stack Promoted from Box")
                    case .ConstantPropFunction:
                        printer("Constant Propagated Function")
                    case .ConstantPropGlobal:
                        printer("Constant Propagated Global")
                    case .ConstantPropInteger:
                        printer("Constant Propagated Integer")
                    case .ConstantPropFloat:
                        printer("Constant Propagated Float")
                    case .ConstantPropString:
                        printer("Constant Propagated String")
                    case .ClosureProp:
                        printer("Closure Propagated")
                    }
                }
                if !kind.optionSet.isEmpty {
                    fatalError("option sets should have been handled earlier")
                }
            }
        case .SpecializationPassID:
            printer(node.index.or(0).description)
        case .BuiltinTypeName:
            printer(node.text)
        case .Number:
            printer(node.index.or(0).description)
        case .InfixOperator:
            printer(node.text + " infix")
        case .PrefixOperator:
            printer(node.text + " prefix")
        case .PostfixOperator:
            printer(node.text + " postfix")
        case .LazyProtocolWitnessTableAccessor:
            printer("lazy protocol witness table accessor for type ")
            print(node.children[0])
            printer(" and conformance ")
            print(node.children[1])
        case .LazyProtocolWitnessTableCacheVariable:
            printer("lazy protocol witness table cache variable for type ")
            print(node.children[0])
            printer(" and conformance ")
            print(node.children[1])
        case .ProtocolSelfConformanceWitnessTable:
            printer("protocol self-conformance witness table for ")
            print(node.children[0])
        case .ProtocolWitnessTableAccessor:
            printer("protocol witness table accessor for ")
            print(node.children[0])
        case .ProtocolWitnessTable:
            printer("protocol witness table for ")
            print(node.children[0])
        case .ProtocolWitnessTablePattern:
            printer("protocol witness table pattern for ")
            print(node.children[0])
        case .GenericProtocolWitnessTable:
            printer("generic protocol witness table for ")
            print(node.children[0])
        case .GenericProtocolWitnessTableInstantiationFunction:
            printer("instantiation function for generic protocol witness table for ")
            print(node.children[0])
        case .ResilientProtocolWitnessTable:
            printer("resilient protocol witness table for ")
            print(node.children[0])
        case .VTableThunk:
            printer("vtable thunk for ")
            print(node.children[1])
            printer(" dispatching to ")
            print(node.children[0])
        case .ProtocolSelfConformanceWitness:
            printer("protocol self-conformance witness for ")
            print(node.children[0])
        case .ProtocolWitness:
            printer("protocol witness for ")
            print(node.children[1])
            printer(" in conformance ")
            print(node.children[0])
        case .PartialApplyForwarder:
            if options.contains(.shortenPartialApply) {
                printer("partial apply")
            } else {
                printer("partial apply forwarder")
            }
            if node.children.isNotEmpty {
                printer(" for ")
                printChildren(node)
            }
        case .PartialApplyObjCForwarder:
            if options.contains(.shortenPartialApply) {
                printer("partial apply")
            } else {
                printer("partial apply ObjC forwarder")
            }
            if node.children.isNotEmpty {
                printer(" for ")
                printChildren(node)
            }
        case .KeyPathGetterThunkHelper,
             .KeyPathSetterThunkHelper:
            if node.kind == .KeyPathGetterThunkHelper {
                printer("key path getter for ")
            } else {
                printer("key path setter for ")
            }
            
            print(node.children[0])
            printer(" : ")
            for child in node.children.dropFirst() {
                if child.kind == .IsSerialized {
                    printer(", ")
                }
                print(child)
            }
        case .KeyPathEqualsThunkHelper,
             .KeyPathHashThunkHelper:
            printer("key path index " + (node.kind == Node.Kind.KeyPathEqualsThunkHelper ? "equality" : "hash") + " operator for ")
            
            var lastChildIndex = node.children.endIndex
            var lastChild = node.children[lastChildIndex]
            if lastChild.kind == .IsSerialized {
                lastChildIndex -= 1
                lastChild = node.children[lastChildIndex]
            }
            
            if lastChild.kind == .DependentGenericSignature {
                print(lastChild)
                lastChildIndex -= 1
            }
            
            printer("(")
            for index in 0...lastChildIndex where index != 0 {
                printer(", ")
                print(node.children[index])
            }
            printer(")")
        case .FieldOffset:
            print(node.children[0]) // directness
            printer("field offset for ")
            print(node.children[1])
        case .EnumCase:
            printer("enum case for ")
            print(node.children[0])
        case .ReabstractionThunk,
             .ReabstractionThunkHelper:
            if options.contains(.shortenThunk) {
                printer("thunk for ")
                print(node.children[node.children.endIndex - 1])
                return nil
            }
            printer("reabstraction thunk ")
            if node.kind == .ReabstractionThunkHelper {
                printer("helper ")
            }
            var children = node.children
            if children.count == 3 {
                print(children.removeFirst())
                printer(" ")
            }
            printer("from ")
            print(children[1])
            printer(" to ")
            print(children[0])
        case .ReabstractionThunkHelperWithSelf:
            printer("reabstraction thunk ")
            var children = node.children
            if (children.count == 4) {
                print(children.removeFirst())
                printer(" ")
            }
            printer("from ")
            print(children[2])
            printer(" to ")
            print(children[1])
            printer(" self ")
            print(children[0])
        case .MergedFunction:
            if !options.contains(.shortenThunk) {
                printer("merged ")
            }
        case .TypeSymbolicReference:
            printer("type symbolic reference 0x")
            printer(node.index.or(0).hex)
        case .OpaqueTypeDescriptorSymbolicReference:
            printer("opaque type symbolic reference 0x")
            printer(node.index.or(0).hex)
        case .DynamicallyReplaceableFunctionKey:
            if !options.contains(.shortenThunk) {
                printer("dynamically replaceable key for ")
            }
        case .DynamicallyReplaceableFunctionImpl:
            if !options.contains(.shortenThunk) {
                printer("dynamically replaceable thunk for ")
            }
        case .DynamicallyReplaceableFunctionVar:
            if !options.contains(.shortenThunk) {
                printer("dynamically replaceable variable for ")
            }
        case .ProtocolSymbolicReference:
            printer("protocol symbolic reference 0x")
            printer(node.index.or(0).hex)
        case .GenericTypeMetadataPattern:
            printer("generic type metadata pattern for ")
            print(node.children[0])
        case .Metaclass:
            printer("metaclass for ")
            print(node.children[0])
        case .ProtocolSelfConformanceDescriptor:
            printer("protocol self-conformance descriptor for ")
            print(node.children[0])
        case .ProtocolConformanceDescriptor:
            printer("protocol conformance descriptor for ")
            print(node.children[0])
        case .ProtocolDescriptor:
            printer("protocol descriptor for ")
            print(node.children[0])
        case .ProtocolRequirementsBaseDescriptor:
            printer("protocol requirements base descriptor for ")
            print(node.children[0])
        case .FullTypeMetadata:
            printer("full type metadata for ")
            print(node.children[0])
        case .TypeMetadata:
            printer("type metadata for ")
            print(node.children[0])
        case .TypeMetadataAccessFunction:
            printer("type metadata accessor for ")
            print(node.children[0])
        case .TypeMetadataInstantiationCache:
            printer("type metadata instantiation cache for ")
            print(node.children[0])
        case .TypeMetadataInstantiationFunction:
            printer("type metadata instantiation function for ")
            print(node.children[0])
        case .TypeMetadataSingletonInitializationCache:
            printer("type metadata singleton initialization cache for ")
            print(node.children[0])
        case .TypeMetadataCompletionFunction:
            printer("type metadata completion function for ")
            print(node.children[0])
        case .TypeMetadataDemanglingCache:
            printer("demangling cache variable for type metadata for ")
            print(node.children[0])
        case .TypeMetadataLazyCache:
            printer("lazy cache variable for type metadata for ")
            print(node.children[0])
        case .AssociatedConformanceDescriptor:
            printer("associated conformance descriptor for ")
            print(node.children[0])
            printer(".")
            print(node.children[1])
            printer(": ")
            print(node.children[2])
        case .DefaultAssociatedConformanceAccessor:
            printer("default associated conformance accessor for ")
            print(node.children[0])
            printer(".")
            print(node.children[1])
            printer(": ")
            print(node.children[2])
        case .AssociatedTypeDescriptor:
            printer("associated type descriptor for ")
            print(node.children[0])
        case .AssociatedTypeMetadataAccessor:
            printer("associated type metadata accessor for ")
            print(node.children[1])
            printer(" in ")
            print(node.children[0])
        case .BaseConformanceDescriptor:
            printer("base conformance descriptor for ")
            print(node.children[0])
            printer(": ")
            print(node.children[1])
        case .DefaultAssociatedTypeMetadataAccessor:
            printer("default associated type metadata accessor for ")
            print(node.children[0])
        case .AssociatedTypeWitnessTableAccessor:
            printer("associated type witness table accessor for ")
            print(node.children[1])
            printer(" : ")
            print(node.children[2])
            printer(" in ")
            print(node.children[0])
        case .BaseWitnessTableAccessor:
            printer("base witness table accessor for ")
            print(node.children[1])
            printer(" in ")
            print(node.children[0])
        case .ClassMetadataBaseOffset:
            printer("class metadata base offset for ")
            print(node.children[0])
        case .PropertyDescriptor:
            printer("property descriptor for ")
            print(node.children[0])
        case .NominalTypeDescriptor:
            printer("nominal type descriptor for ")
            print(node.children[0])
        case .OpaqueTypeDescriptor:
            printer("opaque type descriptor for ")
            print(node.children[0])
        case .OpaqueTypeDescriptorAccessor:
            printer("opaque type descriptor accessor for ")
            print(node.children[0])
        case .OpaqueTypeDescriptorAccessorImpl:
            printer("opaque type descriptor accessor impl for ")
            print(node.children[0])
        case .OpaqueTypeDescriptorAccessorKey:
            printer("opaque type descriptor accessor key for ")
            print(node.children[0])
        case .OpaqueTypeDescriptorAccessorVar:
            printer("opaque type descriptor accessor var for ")
            print(node.children[0])
        case .CoroutineContinuationPrototype:
            printer("coroutine continuation prototype for ")
            print(node.children[0])
        case .ValueWitness:
            printer(node.children[0].valueWitnessKind!.name)
            if options.contains(.shortenValueWitness) {
                printer(" for ")
            } else {
                printer(" value witness for ")
            }
            print(node.children[1])
        case .ValueWitnessTable:
            printer("value witness table for ")
            print(node.children[0])
        case .BoundGenericClass,
             .BoundGenericStructure,
             .BoundGenericEnum,
             .BoundGenericProtocol,
             .BoundGenericOtherNominalType,
             .BoundGenericTypeAlias:
            printBoundGeneric(node: node)
        case .DynamicSelf:
            printer("Self")
            
        case .SILBoxType:
            printer("@box ")
            print(node.children[0])
        case .Metatype:
            var index = 0
            if node.numberOfChildren == 2 {
                let repr = node.children[index]
                print(repr)
                printer(" ")
                index += 1
            }
            let type = node.children[index].children[0]
            printWithParens(type)
            if type.isExistentialType {
                printer(".Protocol")
            } else {
                printer(".Type")
            }
        case .ExistentialMetatype:
            var index = 0
            if node.numberOfChildren == 2 {
                let repr = node.children[index]
                print(repr)
                printer(" ")
                index += 1
            }
            let type = node.children[index]
            print(type)
            printer(".Type")
        case .MetatypeRepresentation:
            printer(node.text)
        case .AssociatedTypeRef:
            print(node.children[0])
            printer("." + node.children[1].text)
        case .ProtocolList:
            guard let typeList = node.children.first else {
                return nil
            }
            if typeList.numberOfChildren == 0 {
                printer("Any")
            } else {
                printChildren(typeList, separator: " & ")
            }
        case .ProtocolListWithClass:
            if node.numberOfChildren < 2 {
                return nil
            }
            let protocols = node.children[0]
            let superclass = node.children[1]
            print(superclass)
            printer(" & ")
            if protocols.children.isEmpty {
                return nil
            }
            let typeList = protocols.children[0]
            printChildren(typeList, separator: " & ")
        case .ProtocolListWithAnyObject:
            if node.children.isEmpty {
                return nil
            }
            let protocols = node.children[0]
            if protocols.children.isEmpty {
                return nil
            }
            let typeList = protocols.children[0]
            if typeList.numberOfChildren > 0 {
                printChildren(typeList, separator: " & ")
                printer(" & ")
            }
            if options.contains([.qualifyEntities, .displayStdlibModule]) {
                printer(.STDLIB_NAME + ".")
            }
            printer("AnyObject")
        case .AssociatedType:
            break
        case .OwningAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "owningAddressor")
        case .OwningMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "owningMutableAddressor")
        case .NativeOwningAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "nativeOwningAddressor")
        case .NativeOwningMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "nativeOwningMutableAddressor")
        case .NativePinningAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "nativePinningAddressor")
        case .NativePinningMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "nativePinningMutableAddressor")
        case .UnsafeAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "unsafeAddressor")
        case .UnsafeMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "unsafeMutableAddressor")
        case .GlobalGetter:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "getter")
        case .Getter:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "getter")
        case .Setter:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "setter")
        case .MaterializeForSet:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "materializeForSet")
        case .WillSet:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "willset")
        case .DidSet:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "didset")
        case .ReadAccessor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "read")
        case .ModifyAccessor:
            return printAbstractStorage(node: node.children[0], asPrefixContext: asPrefixContext, extraName: "modify")
        case .Allocator:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: false, extraName: node.children[0].isClassType ? "__allocating_init" : "init")
        case .Constructor:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: node.numberOfChildren > 2, extraName: "init")
        case .Destructor:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "deinit")
        case .Deallocator:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: node.children[0].isClassType ? "__deallocating_deinit" : "deinit")
        case .IVarInitializer:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "__ivar_initializer")
        case .IVarDestroyer:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "__ivar_destroyer")
        case .ProtocolConformance:
            let (child0, child1, child2) = (node.children[0], node.children[1], node.children[2])
            if node.numberOfChildren == 4 {
                // TODO: check if this is correct
                printer("property behavior storage of ")
                print(child2)
                printer(" in ")
                print(child0)
                printer(" : ")
                print(child1)
            } else {
                print(child0)
                if options.contains(.displayProtocolConformances) {
                    printer(" : ")
                    print(child1)
                    printer(" in ")
                    print(child2)
                }
            }
        case .TypeList:
            printChildren(node)
        case .LabelList:
            return nil
        case .ImplDifferentiabilityKind:
            printer("@differentiable")
            if let kind = node.mangledDifferentiabilityKind {
                switch kind {
                case .normal:
                    break
                case .linear:
                    printer("(_linear)")
                case .forward:
                    printer("(_forward)")
                case .reverse:
                    printer("(reverse)")
                case .nonDifferentiable:
                    assertionFailure("Impossible case 'NonDifferentiable'")
                }
                return nil
            }
        case .ImplEscaping:
            printer("@escaping")
        case .ImplConvention:
            printerText(node)
        case .ImplFunctionConventionName:
            assert(false, "Already handled in ImplFunctionConvention")
            printer("@error ")
            printChildren(node, separator: " ")
        case .ImplYield:
            printer("@yields ")
            printChildren(node, separator: " ")
        case .ImplParameter,
             .ImplResult:
            // Children: `convention, differentiability?, type`
            // Print convention.
            print(node.children[0])
            printer(" ")
            // Print differentiability, if it exists.
            if node.numberOfChildren == 3 {
                print(node.children[1])
            }
            // Print type.
            print(node.lastChild)
        case .ImplFunctionType:
            printImplFunctionType(function: node)
        case .ImplInvocationSubstitutions:
            printer("for <")
            printChildren(node.children[0], separator: ", ")
            printer(">")
        case .ImplPatternSubstitutions:
            printer("@substituted ")
            print(node.children[0])
            printer(" for <")
            printChildren(node.children[1], separator: ", ")
            printer(">")
        case .ErrorType:
            printer("<ERROR TYPE>")
        case .DependentPseudogenericSignature,
             .DependentGenericSignature:
            printer("<")
            let numChildren = node.numberOfChildren
            var depth: Int = 0
            while depth < numChildren, node.getChild(depth).kind == .DependentGenericParamCount {
                defer {
                    depth += 1
                }
                let child = node.getChild(depth)
                if depth != 0 {
                    printer("><")
                }
                let count = child.index.or(0)
                for index in 0..<count {
                    if index > 0 {
                        printer(", ")
                    }
                    // Limit the number of printed generic parameters. In practice this
                    // it will never be exceeded. The limit is only imporant for malformed
                    // symbols where count can be really huge.
                    if index >= 128 {
                        printer("...")
                        break
                    }
                    // FIXME: Depth won't match when a generic signature applies to a
                    // method in generic type context.
                    printer(options.genericParameterName(depth: UInt64(depth), index: UInt64(index)))
                }
            }
            
            if depth != node.numberOfChildren {
                if options.contains(.displayWhereClauses) {
                    printer(" where ")
                    for index in Int(depth)..<node.numberOfChildren {
                        if index > depth {
                            printer(", ")
                        }
                        print(node.children[index])
                    }
                }
            }
            printer(">")
        case .DependentGenericParamCount:
            fatalError("should be printed as a child of a DependentGenericSignature")
        case .DependentGenericConformanceRequirement:
            let type = node.children[0]
            let reqt = node.children[1]
            print(type)
            printer(": ")
            print(reqt)
        case .DependentGenericLayoutRequirement:
            let type = node.children[0]
            let layout = node.children[1]
            
            print(type)
            printer(": ")
            
            assert(layout.kind == .Identifier)
            assert(layout.text.count == 1)
            
            let character = layout.text[0]
            switch character {
            case "U":
                printer("_UnknownLayout")
            case "R":
                printer("_RefCountedObject")
            case "N":
                printer("_NativeRefCountedObject")
            case "C":
                printer("AnyObject")
            case "D":
                printer("_NativeClass")
            case "T":
                printer("_Trivial")
            case "E", "e":
                printer("_Trivial")
            case "M", "m":
                printer("_TrivialAtMost")
            default:
                break
            }
            if node.numberOfChildren > 2 {
                printer("(")
                print(node.children[2])
                if node.numberOfChildren > 3 {
                    printer(", ")
                    print(node.children[3])
                }
                printer(")")
            }
        case .DependentGenericSameTypeRequirement:
            let first = node.children[0]
            let second = node.children[1]
            print(first)
            printer(" == ")
            print(second)
        case .DependentGenericParamType:
            let index = node.children[1].index.or(0)
            let depth = node.children[0].index.or(0)
            printer(options.genericParameterName(depth: UInt64(depth), index: UInt64(index)))
        case .DependentGenericType:
            let signature = node.children[0]
            let dependentType = node.children[1]
            print(signature)
            if dependentType.isNeedSpaceBeforeType {
                printer(" ")
            }
            print(dependentType)
        case .DependentMemberType:
            let base = node.children[0]
            print(base)
            printer(".")
            let associatedType = node.children[1]
            print(associatedType)
        case .DependentAssociatedTypeRef:
            if node.numberOfChildren > 1 {
                print(node.children[1])
                printer(".")
            }
            print(node.children[0])
        case .ReflectionMetadataBuiltinDescriptor:
            printer("reflection metadata builtin descriptor ")
            print(node.children[0])
        case .ReflectionMetadataFieldDescriptor:
            printer("reflection metadata field descriptor ")
            print(node.children[0])
        case .ReflectionMetadataAssocTypeDescriptor:
            printer("reflection metadata associated type descriptor ")
            print(node.children[0])
        case .ReflectionMetadataSuperclassDescriptor:
            printer("reflection metadata superclass descriptor ")
            print(node.children[0])
        case .AsyncAnnotation:
            printer(" async ")
        case .ThrowsAnnotation:
            printer(" throws ")
        case .EmptyList:
            printer(" empty-list ")
        case .FirstElementMarker:
            printer(" first-element-marker ")
        case .VariadicMarker:
            printer(" variadic-marker ")
        case .SILBoxTypeWithLayout:
            assert(node.numberOfChildren == 1 || node.numberOfChildren == 3)
            let layout = node.children[0]
            assert(layout.kind == .SILBoxLayout)
            var genericArgs: Node?
            if node.numberOfChildren == 3 {
                let signature = node.children[1]
                assert(signature.kind == .DependentGenericSignature)
                genericArgs = node.children[2]
                assert(genericArgs?.kind == .TypeList)
                print(signature)
                printer(" ")
            }
            print(layout)
            if let args = genericArgs {
                printer(" <")
                for (index, child) in args.children.enumerated() {
                    if index > 0 {
                        printer(", ")
                    }
                    print(child)
                }
                printer(">")
            }
        case .SILBoxLayout:
            printer("{")
            for (index, child) in node.children.enumerated() {
                if index > 0 {
                    printer(",")
                }
                printer(" ")
                print(child)
            }
            printer(" }")
        case .SILBoxImmutableField,
             .SILBoxMutableField:
            printer(node.kind == .SILBoxImmutableField ? "let " : "var ")
            assert(node.numberOfChildren == 1 && node.children[0].kind == .Type)
            print(node.children[0])
        case .AssocTypePath:
            printChildren(node, separator: ".")
        case .ModuleDescriptor:
            printer("module descriptor ")
            print(node.children[0])
        case .AnonymousDescriptor:
            printer("anonymous descriptor ")
            print(node.children[0])
        case .ExtensionDescriptor:
            printer("extension descriptor ")
            print(node.children[0])
        case .AssociatedTypeGenericParamRef:
            printer("generic parameter reference for associated type ")
            printChildren(node)
        case .AnyProtocolConformanceList:
            printChildren(node)
        case .ConcreteProtocolConformance:
            printer("concrete protocol conformance ")
            if let index = node.index {
                printer("#" + index.description + " ")
            }
            printChildren(node)
        case .DependentAssociatedConformance:
            printer("dependent associated conformance ")
            printChildren(node)
        case .DependentProtocolConformanceAssociated:
            printer("dependent associated protocol conformance ")
            printOptionalIndex(node.children[2])
            print(node.children[0])
            print(node.children[1])
        case .DependentProtocolConformanceInherited:
            printer("dependent inherited protocol conformance ")
            printOptionalIndex(node.children[2])
            print(node.children[0])
            print(node.children[1])
        case .DependentProtocolConformanceRoot:
            printer("dependent root protocol conformance ")
            printOptionalIndex(node.children[2])
            print(node.children[0])
            print(node.children[1])
        case .ProtocolConformanceRefInTypeModule:
            printer("protocol conformance ref (type's module) ")
            printChildren(node)
        case .ProtocolConformanceRefInProtocolModule:
            printer("protocol conformance ref (protocol's module) ")
            printChildren(node)
        case .ProtocolConformanceRefInOtherModule:
            printer("protocol conformance ref (retroactive) ")
            printChildren(node)
        case .SugaredOptional:
            printWithParens(node.children[0])
            printer("?")
        case .SugaredArray:
            printer("[")
            print(node.children[0])
            printer("]")
        case .SugaredDictionary:
            printer("[")
            print(node.children[0])
            printer(" : ")
            print(node.children[1])
            printer("]")
        case .SugaredParen:
            printer("(")
            print(node.children[0])
            printer(")")
        case .OpaqueReturnType:
            printer("some")
        case .OpaqueReturnTypeOf:
            printer("<<opaque return type of ")
            printChildren(node)
            printer(">>")
        case .OpaqueType:
            print(node.children[0])
            printer(".")
            print(node.children[1])
        case .AccessorFunctionReference:
            printer("accessor function at " + node.index.or(0).description)
        case .CanonicalSpecializedGenericMetaclass:
            printer("specialized generic metaclass for ")
            print(node.children[0])
        case .CanonicalSpecializedGenericTypeMetadataAccessFunction:
            printer("canonical specialized generic type metadata accessor for ")
            print(node.children[0])
        case .MetadataInstantiationCache:
            printer("metadata instantiation cache for ")
            print(node.children[0])
        case .NoncanonicalSpecializedGenericTypeMetadata:
            printer("noncanonical specialized generic type metadata for ")
            print(node.children[0])
        case .NoncanonicalSpecializedGenericTypeMetadataCache:
            printer("cache variable for noncanonical specialized generic type metadata for ")
            print(node.children[0])
        case .GlobalVariableOnceToken,
             .GlobalVariableOnceFunction:
            printer(node.kind == .GlobalVariableOnceToken
                        ? "one-time initialization token for "
                        : "one-time initialization function for ")
            print(node.children[1])
        case .GlobalVariableOnceDeclList:
            if node.numberOfChildren == 1 {
                print(node.children[0])
            } else {
                printer("(")
                printChildren(node, separator: ", ")
                printer(")")
            }
        case .PredefinedObjCAsyncCompletionHandlerImpl:
            printer("predefined ")
            fallthrough
        case .ObjCAsyncCompletionHandlerImpl:
            printer("@objc completion handler block implementation for ")
            print(node.children[0])
            printer(" with result type ")
            print(node.children[1])
        case .CanonicalPrespecializedGenericTypeCachingOnceToken:
            printer("flag for loading of canonical specialized generic type metadata for ")
            print(node.children[0])
        case .ConcurrentFunctionType:
            printer("@Sendable ")
            return nil
        case .GlobalActorFunctionType:
            if node.getNumChildren() > 0 {
                printer("@")
                print(node.firstChild)
                printer(" ")
            }
            return nil
        case .DifferentiableFunctionType:
            printer("@differentiable")
            if let kind = node.mangledDifferentiabilityKind {
                switch kind {
                case .forward:
                    printer("(_forward)")
                case .reverse:
                    printer("(reverse)")
                case .linear:
                    printer("(_linear)")
                case .normal, .nonDifferentiable:
                    assert(false, "Unexpected case NonDifferentiable")
                }
            }
            printer(" ")
            return nil
        case .ImplParameterResultDifferentiability:
            // Skip if text is empty.
            if node.text.isEmpty {
                return nil
            }
            // Otherwise, print with trailing space.
            printer(node.text + " ")
            return nil
        case .ImplFunctionAttribute:
            printer(node.text)
            return nil
        case .ImplFunctionConvention:
            printer("@convention(")
            switch node.getNumChildren() {
            case 1:
                printer(node.firstChild.text)
            case 2:
                printer(node.firstChild.text + ", mangledCType: \"")
                print(node.children(0))
                printer("\"")
            default:
                assert(false, "Unexpected numChildren for ImplFunctionConvention")
            }
            printer(")")
            return nil
        case .ImplErrorResult:
            printer("@error ")
            printChildren(node, separator: " ")
            return nil
        case .PropertyWrapperInitFromProjectedValue:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .noType, /*hasName*/hasName: false, extraName: "property wrapper init from projected value")
        case .ReabstractionThunkHelperWithGlobalActor:
            print(node.getChild(0))
            printer(" with global actor constraint ")
            print(node.getChild(1))
            return nil
        case .AsyncFunctionPointer:
            printer("async function pointer to ")
            return nil
        case .AutoDiffFunction, .AutoDiffDerivativeVTableThunk:
            var prefixEndIndex = 0
            while prefixEndIndex != node.getNumChildren() && node.getChild(prefixEndIndex).getKind() != .AutoDiffFunctionKind {
                prefixEndIndex += 1
            }
            let funcKind = node.getChild(prefixEndIndex)
            let paramIndices = node.getChild(prefixEndIndex + 1)
            let resultIndices = node.getChild(prefixEndIndex + 2)
            if kind == .AutoDiffDerivativeVTableThunk {
                printer("vtable thunk for ")
            }
            print(funcKind)
            printer(" of ")
            var optionalGenSig: Node?
            for index in 0..<prefixEndIndex {
                // The last node may be a generic signature. If so, print it later.
                if (index == prefixEndIndex - 1 && node.getChild(index).getKind() == .DependentGenericSignature) {
                    optionalGenSig = node.getChild(index)
                    break
                }
                print(node.getChild(index))
            }
            if options.contains(.shortenThunk) {
                return nil
            }
            printer(" with respect to parameters ")
            print(paramIndices)
            printer(" and results ")
            print(resultIndices)
            if let optionalGenSig = optionalGenSig, options.contains(.displayWhereClauses) {
                printer(" with ")
                print(optionalGenSig)
            }
            return nil
        case .AutoDiffFunctionKind:
            if let kind = AutoDiffFunctionKind(rawValue: node.text) {
                switch kind {
                case .JVP:
                    printer("forward-mode derivative")
                case .VJP:
                    printer("reverse-mode derivative")
                case .Differential:
                    printer("differential")
                case .Pullback:
                    printer("pullback")
                }
            }
            return nil
        case .AutoDiffSelfReorderingReabstractionThunk:
            printer("autodiff self-reordering reabstraction thunk ")
            var childIt = 0
            let fromType = node.getChild(childIt.advancedAfter())
            let toType = node.getChild(childIt.advancedAfter())
            if options.contains(.shortenThunk) {
                printer("for ")
                print(fromType)
                return nil
            }
            let optionalGenSig: Node? = toType.kind == .DependentGenericSignature ? node.getChild(childIt.advancedAfter()) : nil
            printer("for ")
            print(node.getChild(childIt.advancedAfter())) // kind
            if let node = optionalGenSig {
                print(node)
                printer(" ")
            }
            printer(" from ")
            print(fromType)
            printer(" to ")
            print(toType)
            return nil
        case .AutoDiffSubsetParametersThunk:
            printer("autodiff subset parameters thunk for ")
            var currentIndex = node.getNumChildren() - 1
            let toParamIndices = node.getChild(currentIndex)
            currentIndex -= 1
            let resultIndices = node.getChild(currentIndex)
            currentIndex -= 1
            let paramIndices = node.getChild(currentIndex)
            currentIndex -= 1
            let kind = node.getChild(currentIndex)
            currentIndex -= 1
            print(kind)
            printer(" from ")
            // Print the "from" thing.
            if (currentIndex == 0) {
                print(node.getFirstChild()) // the "from" type
            } else {
                if currentIndex > 0 {
                    for index in 0..<currentIndex { // the "from" global
                        print(node.getChild(index))
                    }
                }
            }
            if options.contains(.shortenThunk) {
                return nil
            }
            printer(" with respect to parameters ")
            print(paramIndices)
            printer(" and results ")
            print(resultIndices)
            printer(" to parameters ")
            print(toParamIndices)
            if currentIndex > 0 {
                printer(" of type ")
                print(node.getChild(currentIndex)) // "to" type
            }
            return nil
        case .DifferentiabilityWitness:
            let kindNodeIndex = node.getNumChildren() - (node.lastChild.getKind() == .DependentGenericSignature ? 4 : 3)
            let kind = node.getChild(kindNodeIndex).mangledDifferentiabilityKind
            switch kind {
            case .forward:
                printer("forward-mode")
            case .reverse:
                printer("reverse-mode")
            case .normal:
                printer("normal")
            case .linear:
                printer("linear")
            default:
                assert(false, "Impossible case")
            }
            printer(" differentiability witness for ")
            var idx = 0
            while idx < node.numberOfChildren, node.children(idx).kind != .Index {
                print(node.children(idx))
                idx += 1
            }
            idx += 1 // kind (handled earlier)
            printer(" with respect to parameters ")
            print(node.getChild(idx)) // parameter indices
            idx += 1
            printer(" and results ")
            print(node.getChild(idx))
            idx += 1
            if idx < node.getNumChildren() {
                let genSig = node.getChild(idx)
                assert(genSig.getKind() == .DependentGenericSignature)
                printer(" with ")
                print(genSig)
            }
            return nil
        case .NoDerivative:
            printer("@noDerivative ")
            print(node.getChild(0))
            return nil
        case .IndexSubset:
            printer("{")
            let text = node.getText()
            var printedAnyIndex = false
            for (offset, char) in text.enumerated() {
                if char != "S" {
                    assert(char == "U")
                    continue
                }
                if printedAnyIndex {
                    printer(", ")
                }
                printer(String(offset))
                printedAnyIndex = true
            }
            printer("}")
            return nil
        case .AsyncAwaitResumePartialFunction:
            if options.contains(.showAsyncResumePartial) {
                printer("(")
                print(node.getChild(0))
                printer(")")
                printer(" await resume partial function for ")
            }
            return nil
        case .AsyncSuspendResumePartialFunction:
            if options.contains(.showAsyncResumePartial) {
                printer("(")
                print(node.getChild(0))
                printer(")")
                printer(" suspend resume partial function for ")
            }
            return nil
        }
        return nil
    }
    
    private mutating func printEntity(entity: Node,
                                      asPrefixContext: Bool,
                                      typePrinting: TypePrinting,
                                      hasName: Bool,
                                      extraName: String? = nil,
                                      extraIndex: Int = -1,
                                      overwriteName: String? = nil) -> Node? {
        var entity = entity
        var typePrinting = typePrinting
        var genericFunctionTypeList: Node?
        if entity.kind == .BoundGenericFunction {
            genericFunctionTypeList = entity.children[1]
            entity = entity.children[0]
        }
        // Either we print the context in prefix form "<context>.<name>" or in
        // suffix form "<name> in <context>".
        var multiWordName = extraName?.contains(" ") ?? false
        // Also a local name (e.g. Mystruct #1) does not look good if its context is
        // printed in prefix form.
        let localName = hasName && entity.children[1].kind == .LocalDeclName
        if localName, options.contains(.displayLocalNameContexts) {
            multiWordName = true
        }
        if asPrefixContext && (typePrinting != .noType || multiWordName) {
            // If the context has a type to be printed, we can't use the prefix form.
            return entity
        }
        var postfixContext: Node?
        let context = entity.children[0]
        
        if printContext(context) {
            if multiWordName {
                // If the name contains some spaces we don't print the context now but
                // later in suffix form.
                postfixContext = context
            } else {
                let currentPosition = printText.count
                postfixContext = print(context, asPrefixContext: true)
                
                // Was the context printed as prefix?
                if printText.count != currentPosition {
                    printer(".")
                }
            }
        }
        if hasName || overwriteName.isNotEmpty {
            assert(extraIndex < 0, "Can't have a name and extra index")
            var extraName = extraName
            if let name = extraName?.emptyToNil(), multiWordName {
                printer(name)
                printer(" of ")
                extraName = ""
            }
            let currentPos = printText.count
            if let name = overwriteName?.emptyToNil() {
                printer(name)
            } else {
                let name = entity.children[1]
                if name.kind != .PrivateDeclName {
                    print(name)
                }
                if let privateName = entity.childIf(.PrivateDeclName) {
                    print(privateName)
                }
            }
            if printText.count != currentPos, extraName.isNotEmpty {
                printer(".")
            }
        }
        if let name = extraName?.emptyToNil() {
            printer(name)
            if extraIndex >= 0 {
                printerIndex(extraIndex)
            }
        }
        if typePrinting != .noType {
            guard var type = entity.childIf(.Type) else {
                assertionFailure("malformed entity")
                isValid = false
                return nil
            }
            type = type.children[0]
            if typePrinting == .functionStyle {
                // We expect to see a function type here, but if we don't, use the colon.
                var t = type
                while t.kind == .DependentGenericType {
                    t = t.children[1].children[0]
                }
                switch t.kind {
                case .FunctionType, .NoEscapeFunctionType, .UncurriedFunctionType, .CFunctionPointer, .ThinFunctionType:
                    break
                default:
                    typePrinting = .withColon
                }
            }
            if typePrinting == .withColon {
                if options.contains(.displayEntityTypes) {
                    printer(" : ")
                    printEntityType(entity: entity, type: type, genericFunctionTypeList: genericFunctionTypeList)
                }
            } else {
                assert(typePrinting == .functionStyle)
                if multiWordName || needSpaceBeforeType(type: type) {
                    printer(" ")
                }
                printEntityType(entity: entity, type: type, genericFunctionTypeList: genericFunctionTypeList)
            }
        }
        
        if !asPrefixContext, let context = postfixContext, (!localName || options.contains(.displayLocalNameContexts)) {
            if entity.kind.in(.DefaultArgumentInitializer, .Initializer, .PropertyWrapperBackingInitializer) {
                printer(" of ")
            } else {
                printer(" in ")
            }
            print(context)
            postfixContext = nil
        }
        return postfixContext
    }
    
    mutating func printEntityType(entity: Node, type: Node, genericFunctionTypeList: Node?) {
        let labelList = entity.childIf(.LabelList)
        var type = type
        if labelList != nil || genericFunctionTypeList != nil {
            if let node = genericFunctionTypeList {
                printer("<")
                printChildren(node, separator: ", ")
                printer(">")
            }
            if type.kind == .DependentGenericType {
                if genericFunctionTypeList == nil {
                    print(type.children[0]) // generic signature
                }
                let dependentType = type.children[1]
                if (needSpaceBeforeType(type: dependentType)) {
                    printer(" ")
                }
                type = dependentType.children[0]
            }
            
            printFunctionType(labelList: labelList, type: type)
        } else {
            print(type)
        }
    }
    
    mutating func printChildren(nodes: [Node], separator: String? = nil) {
        for (offset, node) in nodes.enumerated() {
            if let separator = separator, offset > 0 {
                printer(separator)
            }
            print(node)
        }
    }
    
    mutating func printChildren(_ node: Node, separator: String? = nil) {
        printChildren(nodes: node.children, separator: separator)
    }
    
    func printContext(_ context: Node) -> Bool {
        if !options.contains(.qualifyEntities) {
            return false
        }
        if context.kind == .Module {
            if context.text == .STDLIB_NAME {
                return options.contains(.displayStdlibModule)
            }
            if context.text == .MANGLING_MODULE_OBJC {
                return options.contains(.displayObjCModule)
            }
            if context.text == DemangleOptions.hidingCurrentModule {
                return false
            }
            if context.text.hasPrefix(.LLDB_EXPRESSIONS_MODULE_NAME_PREFIX) {
                return options.contains(.displayDebuggerGeneratedModule)
            }
        }
        return true
    }
    
    mutating func printFunctionType(labelList: Node? = nil, type: Node) {
        if type.children.count < 2 || type.children.count > 5 {
            isValid = false
            return
        }
        
        func printConventionWithMangledCType(convention: String) {
            printer("@convention(" + convention)
            if type.children[0].kind == .ClangType {
                printer(", mangledCType: \"")
                print(type.children[0])
                printer("\"")
            }
            printer(") ")
        }
        
        switch type.kind {
        case .FunctionType,
             .UncurriedFunctionType,
             .NoEscapeFunctionType:
            break
        case .AutoClosureType,
             .EscapingAutoClosureType:
            printer("@autoclosure ")
        case .ThinFunctionType:
            printer("@convention(thin) ")
        case .CFunctionPointer:
            printConventionWithMangledCType(convention: "c")
        case .EscapingObjCBlock:
            printer("@escaping ")
            fallthrough
        case .ObjCBlock:
            printConventionWithMangledCType(convention: "block")
        default:
            assertionFailure("Unhandled function type in printFunctionType!")
        }
        
        var startIndex: Int = 0
        var isSendable = false
        var isAsync = false
        var isThrows = false
        var diffKind = MangledDifferentiabilityKind.nonDifferentiable
        if type.children[startIndex].kind == .GlobalActorFunctionType {
            print(type.getChild(startIndex))
            startIndex += 1
        }
        if type.children[startIndex].kind == .DifferentiableFunctionType {
            diffKind = type.children[startIndex].mangledDifferentiabilityKind ?? .nonDifferentiable
            startIndex += 1
        }
        if type.children[startIndex].kind == .ClangType {
            // handled earlier
            startIndex += 1
        }
        if type.children[startIndex].kind == .ThrowsAnnotation {
            startIndex += 1
            isThrows = true
        }
        if type.children[startIndex].kind == .ConcurrentFunctionType {
            startIndex += 1
            isSendable = true
        }
        if type.children[startIndex].kind == .AsyncAnnotation {
            startIndex += 1
            isAsync = true
        }
        
        switch diffKind {
        case .forward:
            printer("@differentiable(_forward) ")
        case .reverse:
            printer("@differentiable(reverse) ")
        case .linear:
            printer("@differentiable(_linear) ")
        case .normal:
            printer("@differentiable ")
        case .nonDifferentiable:
            break
        }
        
        if isSendable {
            printer("@Sendable ")
        }
        
        printFunctionParameters(labelList: labelList,
                                parameterType: type.children[startIndex],
                                showTypes: options.contains(.showFunctionArgumentTypes))
        
        if !options.contains(.showFunctionArgumentTypes) {
            return
        }
        
        if isAsync {
            printer(" async")
        }
        
        if isThrows {
            printer(" throws")
        }
        
        print(type.children[startIndex + 1])
    }
    
    mutating func printFunctionParameters(labelList: Node? = nil, parameterType: Node, showTypes: Bool) {
        if parameterType.kind != .ArgumentTuple {
            isValid = false
            return
        }
        
        var parameters = parameterType.children[0]
        assert(parameters.kind == .Type)
        parameters = parameters.children[0]
        if parameters.kind != .Tuple {
            // only a single not-named parameter
            if showTypes {
                printer("(")
                print(parameters)
                printer(")")
            } else {
                printer("(_:)")
            }
            return
        }
        
        func getLabel(for param: Node, index: Int) -> String {
            guard let label = labelList?.children[index] else {
                assertionFailure()
                return "_"
            }
            assert(label.kind == .Identifier || label.kind == .FirstElementMarker)
            return label.kind == .Identifier ? label.text : "_"
        }
        
        let hasLabels = labelList?.children.count > 0
        
        printer("(")
        parameters.children.interleave { (index, param) in
            assert(param.kind == .TupleElement)
            if hasLabels {
                printer(getLabel(for: param, index: index) + ":")
            } else if !showTypes {
                if let label = param.childIf(.TupleElementName) {
                    printer(label.text + ":")
                } else {
                    printer("_:")
                }
            }
            if hasLabels, showTypes {
                printer(" ")
            }
            if showTypes {
                print(param)
            }
        } betweenHandle: {
            guard showTypes else { return }
            self.printer(", ")
        }
        printer(")")
    }
    
    mutating func printSpecializationPrefix(node: Node, description: String, paramPrefix: String? = nil) {
        if !options.contains(.displayGenericSpecializations) {
            if (!isSpecializationPrefixPrinted) {
                printer("specialized ")
                isSpecializationPrefixPrinted = true
            }
            return
        }
        printer(description + " <")
        var separator = ""
        var argumentNumber = 0
        for child in node.children {
            switch child.kind {
            case .SpecializationPassID:
                // We skip the SpecializationPassID since it does not contain any
                // information that is useful to our users.
                break
            case .IsSerialized:
                printer(separator)
                separator = ", "
                print(child)
            default:
                // Ignore empty specializations.
                if child.children.isNotEmpty {
                    printer(separator)
                    printer(paramPrefix ?? "")
                    separator = ", "
                    switch child.kind {
                    case .FunctionSignatureSpecializationParam:
                        printer("Arg[\(argumentNumber)] = ")
                        printFunctionSigSpecializationParams(node: child)
                    case .FunctionSignatureSpecializationReturn:
                        printer("Return = ")
                        printFunctionSigSpecializationParams(node: child)
                    default:
                        print(child)
                    }
                }
                argumentNumber += 1
            }
        }
        printer("> of ")
    }
    
    mutating func printFunctionSigSpecializationParams(node: Node) {
        var index = 0
        let endIndex = node.children.count
        while index < endIndex {
            let firstChild = node.children[index]
            if let paramKindValue = firstChild.functionSigSpecializationParamKind {
                if let kind = paramKindValue.kind {
                    switch kind {
                    case .BoxToValue,
                         .BoxToStack:
                        print(node.children[index])
                        index += 1
                    case .ConstantPropFunction,
                         .ConstantPropGlobal:
                        printer("[")
                        print(node.children[index])
                        index += 1
                        printer(" : ")
                        let text = node.children[index].text
                        index += 1
                        let demangleName = text.demangleSymbolAsString(with: .defaultOptions)
                        printer(demangleName.emptyToNil() ?? text)
                        printer("]")
                    case .ConstantPropInteger,
                         .ConstantPropFloat:
                        printer("[")
                        print(node.children[index])
                        index += 1
                        printer(" : ")
                        print(node.children[index])
                        index += 1
                        printer("]")
                    case .ConstantPropString:
                        printer("[")
                        print(node.children[index])
                        index += 1
                        printer(" : ")
                        print(node.children[index])
                        index += 1
                        printer("'")
                        print(node.children[index])
                        index += 1
                        printer("'")
                        printer("]")
                    case .ClosureProp:
                        printer("[")
                        print(node.children[index])
                        index += 1
                        printer(" : ")
                        print(node.children[index])
                        index += 1
                        printer(", Argument Types : [")
                        while index < node.children.count {
                            let child = node.children[index]
                            // Until we no longer have a type node, keep demangling.
                            if child.kind != .Type {
                                break
                            }
                            print(child)
                            index += 1
                            
                            // If we are not done, print the ", ".
                            if index < node.children.count, node.children[index].text.emptyToNil() != nil {
                                printer(", ")
                            }
                        }
                        printer("]")
                    }
                } else {
                    assert(paramKindValue.isValidOptionSet, "Invalid OptionSet")
                    print(node.children[index])
                    index += 1
                }
            }
        }
    }
    
    func needSpaceBeforeType(type: Node) -> Bool {
        switch type.kind {
        case .Type:
            return needSpaceBeforeType(type: type.children[0])
        case .FunctionType,
             .NoEscapeFunctionType,
             .UncurriedFunctionType,
             .DependentGenericType:
            return false
        default:
            return true
        }
    }
    
    mutating func printBoundGenericNoSugar(node: Node) {
        guard node.numberOfChildren > 1 else {
            return
        }
        let typelist = node.children[1]
        print(node.children[0])
        printer("<")
        printChildren(typelist, separator: ", ")
        printer(">")
    }
    
    mutating func printBoundGeneric(node: Node) {
        guard node.numberOfChildren > 1 else {
            return
        }
        guard node.numberOfChildren == 2 else {
            printBoundGenericNoSugar(node: node)
            return
        }
        
        if !options.contains(.synthesizeSugarOnTypes) || node.kind == .BoundGenericClass {
            // no sugar here
            printBoundGenericNoSugar(node: node)
            return
        }
        
        // Print the conforming type for a "bound" protocol node "as" the protocol
        // type.
        guard node.kind != .BoundGenericProtocol else {
            printChildren(node.children[1])
            printer(" as ")
            print(node.children[0])
            return
        }
        
        let sugarType = findSugar(node)
        
        switch sugarType {
        case .none:
            printBoundGenericNoSugar(node: node)
        case .optional,
             .implicitlyUnwrappedOptional:
            let type = node.children[1].children[0]
            printWithParens(type)
            printer(sugarType == .optional ? "?" : "!")
        case .array:
            let type = node.children[1].children[0]
            printer("[")
            print(type)
            printer("]")
        case .dictionary:
            let keyType = node.children[1].children[0]
            let valueType = node.children[1].children[1]
            printer("[")
            print(keyType)
            printer(" : ")
            print(valueType)
            printer("]")
            break
        }
    }
    
    mutating func printWithParens(_ type: Node) {
        let needsParens = !type.isSimpleType
        if needsParens {
            printer("(")
        }
        print(type)
        if needsParens {
            printer(")")
        }
    }
    
    mutating func printAbstractStorage(node: Node, asPrefixContext: Bool, extraName: String) -> Node? {
        switch node.kind {
        case .Variable:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: true, extraName: extraName)
        case .Subscript:
            return printEntity(entity: node, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: true, extraName: extraName, extraIndex: -1, overwriteName: "subscript")
        default:
            fatalError("Not an abstract storage node")
        }
    }
    
    mutating func printImplFunctionType(function: Node) {
        var patternSubs: Node?
        var invocationSubs: Node?
        enum State: Int, CaseIterable, Equatable {
            case attrs, inputs, results
            
            var next: State? {
                State(rawValue: self.rawValue + 1)
            }
        }
        var currentState: State = .attrs
        func transitionTo(newState: State) {
            assert(newState.rawValue >= currentState.rawValue)
            while currentState != newState {
                defer {
                    if let state = currentState.next {
                        currentState = state
                    }
                }
                switch currentState {
                case .attrs:
                    if let patternSubs = patternSubs {
                        printer("@substituted ")
                        print(patternSubs.firstChild)
                        printer(" ")
                    }
                    printer("(")
                    continue
                case .inputs:
                    printer(") -> (")
                    continue
                case .results:
                    fatalError("no state after Results")
                }
            }
        }
        for child in function.children {
            if child.kind == .ImplParameter {
                if currentState == .inputs {
                    printer(", ")
                }
                transitionTo(newState: .inputs)
                print(child)
            } else if [Node.Kind.ImplResult, .ImplYield, .ImplErrorResult].contains(child.kind) {
                if currentState == .results {
                    printer(", ")
                }
                transitionTo(newState: .results)
                print(child)
            } else if child.kind == .ImplPatternSubstitutions {
                patternSubs = child
            } else if child.kind == .ImplInvocationSubstitutions {
                invocationSubs = child
            } else {
                assert(currentState == .attrs)
                print(child)
                printer(" ")
            }
        }
        transitionTo(newState: .results)
        printer(")")
        
        if let subs = patternSubs {
            printer(" for <")
            printChildren(subs.children[1])
            printer(">")
        }
        if let subs = invocationSubs {
            printer(" for <")
            printChildren(subs.children[0])
            printer(">")
        }
    }
    
    func findSugar(_ node: Node) -> SugarType {
        if node.numberOfChildren == 1, node.kind == .Type {
            return findSugar(node.children[0])
        }
        
        if node.numberOfChildren != 2 {
            return .none
        }
        
        if node.kind != .BoundGenericEnum, node.kind != .BoundGenericStructure {
            return .none
        }
        
        let unboundType = node.children[0].children[0] // drill through Type
        let typeArgs = node.children[1]
        
        if node.kind == .BoundGenericEnum {
            // Swift.Optional
            if unboundType.children[1].isIdentifier(desired: "Optional"),
               typeArgs.numberOfChildren == 1,
               unboundType.children[0].isSwiftModule {
                return .optional
            }
            
            // Swift.ImplicitlyUnwrappedOptional
            if unboundType.children[1].isIdentifier(desired: "ImplicitlyUnwrappedOptional"),
               typeArgs.numberOfChildren == 1,
               unboundType.children[0].isSwiftModule {
                return .implicitlyUnwrappedOptional
            }
            
            return .none
        }
        
        assert(node.kind == .BoundGenericStructure)
        
        // Array
        if unboundType.children[1].isIdentifier(desired: "Array"),
           typeArgs.numberOfChildren == 1,
           unboundType.children[0].isSwiftModule {
            return .array
        }
        
        // Dictionary
        if unboundType.children[1].isIdentifier(desired: "Dictionary"),
           typeArgs.numberOfChildren == 2,
           unboundType.children[0].isSwiftModule {
            return .dictionary
        }
        
        return .none
    }
    
    mutating func printOptionalIndex(_ node: Node) {
        assert(node.kind == .Index || node.kind == .UnknownIndex)
        if let index = node.index {
            printer("#" + index.description + " ")
        }
    }
    
    func quoted(text: String) -> String {
        var temp = "\""
        for character in text {
            switch character {
            case "\\":
                temp.append("\\\\")
            case "\t":
                temp.append("\\t")
            case "\n":
                temp.append("\\n")
            case "\r":
                temp.append("\\r")
            case "\"":
                temp.append("\\\"")
            case .zero:
                temp.append("\\0")
            default:
                if character < Character(UnicodeScalar(0x20)) || character >= Character(UnicodeScalar(0x7f)) {
                    temp.append("\\x")
                    for scalar in character.unicodeScalars.map(\.utf16).flatMap({ $0 }) {
                        temp.append(String(scalar, radix: 16, uppercase: true))
                    }
                } else {
                    temp.append(character)
                }
            }
        }
        
        temp.append("\"")
        return temp
    }
    
    func genericParameterName(depth: UInt64, index: UInt64) -> String {
        var name = ""
        var index = index
        repeat {
            // A(65) + index
            if let scalar = UnicodeScalar(65) {
                name.append(String(scalar))
            }
            index /= 26
        } while index > 0
        if depth > 0 {
            name.append(depth.description)
        }
        return name
    }
}

private extension NodePrinter {
    
    enum TypePrinting {
        case noType, withColon, functionStyle
    }
    
}