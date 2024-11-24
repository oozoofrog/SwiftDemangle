//
//  NodePrinter.swift
//  Demangling
//
//  Created by spacefrog on 2021/03/30.
//

import Foundation

public enum PrintingError: String, Error {
    case shouldBeHandleInPrintSpecializationPrefix
    case unexpectedCaseNonDifferentiable
}

struct NodePrinter {
    
    private(set) var options: DemangleOptions
    var printText: String = ""
    private(set) var isValid: Bool = true
    var isSpecializationPrefixPrinted = false
    
    let depthLimit = 768
    
    private mutating func setInvalid() {
        isValid = false
    }
    
    mutating private func printer(_ text: String) {
        printText.append(text)
    }
    
    mutating private func printerText(_ node: Node) {
        printer(node.text)
    }
    
    mutating private func printerIndex(_ index: Int) {
        printer(index.description)
    }
    
    mutating private func printerHex(_ index: UInt64?) {
        printer(String(format: "%lld", index ?? 0))
    }
    
    mutating func printRoot(_ node: Node) throws -> String {
        try printNode(node, depth: 0)
        return printText
    }
    
    @discardableResult
    mutating func printNode(_ node: Node?, depth: Int, asPrefixContext: Bool = false) throws -> Node? {
        if depth > depthLimit {
            printer("<<too complex>>")
            return nil
        }
        
        guard let node else {
            printer("<null node pointer>")
            return nil
        }
        let kind = node.kind
        print("Kind: \(kind), depth: \(depth)")
        switch kind {
        case .Static:
            printer("static ")
            try printNode(node.children(0), depth: depth + 1)
        case .AsyncRemoved:
            printer("async demotion of ")
            try printNode(node.children(0), depth: depth + 1)
        case .CurryThunk:
            printer("curry thunk of ")
            try printNode(node.children(0), depth: depth + 1)
        case .SILThunkIdentity:
            printer("identity thunk of ")
            try printNode(node.children(0), depth: depth + 1)
        case .SILThunkHopToMainActorIfNeeded:
            printer("hop to main actor thunk of ")
            try printNode(node.children(0), depth: depth + 1)
        case .DispatchThunk:
            printer("dispatch thunk of ")
            try printNode(node.children(0), depth: depth + 1)
        case .MethodDescriptor:
            printer("method descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .MethodLookupFunction:
            printer("method lookup function for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ObjCMetadataUpdateFunction:
            printer("ObjC metadata update function for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ObjCResilientClassStub:
            printer("ObjC resilient class stub for ")
            try printNode(node.children(0), depth: depth + 1)
        case .FullObjCResilientClassStub:
            printer("full ObjC resilient class stub for ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedBridgedMethod:
            printer("outlined bridged method (\(node.text)) of ")
        case .OutlinedCopy:
            printer("outlined copy of ")
            try printNode(node.children(0), depth: depth + 1)
            if node.numberOfChildren > 1 {
                try printNode(node.children(1), depth: depth + 1)
            }
        case .OutlinedConsume:
            printer("outlined consume of ")
            try printNode(node.children(0), depth: depth + 1)
            if node.numberOfChildren > 1 {
                try printNode(node.children(1), depth: depth + 1)
            }
        case .OutlinedRetain:
            printer("outlined retain of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedRelease:
            printer("outlined release of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedInitializeWithTake:
            printer("outlined init with take of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedInitializeWithCopy,
                .OutlinedInitializeWithCopyNoValueWitness:
            printer("outlined init with copy of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedAssignWithTake,
                .OutlinedAssignWithTakeNoValueWitness:
            printer("outlined assign with take of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedAssignWithCopy,
                .OutlinedAssignWithCopyNoValueWitness:
            printer("outlined assign with copy of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedDestroy,
             .OutlinedDestroyNoValueWitness:
            printer("outlined destroy of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedEnumProjectDataForLoad:
            printer("outlined enum project data for load of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedEnumTagStore:
            printer("outlined enum tag store of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedEnumGetTag:
            printer("outlined enum get tag of ")
            try printNode(node.children(0), depth: depth + 1)
        case .OutlinedVariable:
            printer("outlined variable #\(node.index.or(0)) of ")
        case .OutlinedReadOnlyObject:
            printer("outlined read-only object #\(node.index ?? 0) of ")
        case .Directness:
            printer("\(node.directness.text) ")
        case .AnonymousContext:
            if options.contains([.qualifyEntities, .displayExtensionContexts]) {
                try printNode(node.children(1), depth: depth + 1)
                printer(".(unknown context at ")
                try printNode(node.children(0), depth: depth + 1)
                printer(")")
                if node.numberOfChildren >= 3, node.children(2).numberOfChildren > 0 {
                    printer("<")
                    try printNode(node.children(2), depth: depth + 1)
                    printer(">")
                }
            }
        case .Extension:
            assert(node.numberOfChildren == 2 || node.numberOfChildren == 3, "Extension expects 2 or 3 children.")
            if options.contains([.qualifyEntities, .displayExtensionContexts]) {
                printer("(extension in ")
                // Print the module where extension is defined.
                try printNode(node.children(0), depth: depth + 1, asPrefixContext: true)
                printer("):")
            }
            try printNode(node.children(1), depth: depth + 1)
            if node.numberOfChildren == 3 {
                // Currently the runtime does not mangle the generic signature.
                // This is an open to-do in swift::_buildDemanglingForContext().
                if !options.contains(.printForTypeName) {
                    try printNode(node.children(2), depth: depth + 1)
                }
            }
        case .Variable:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: true)
        case .Function, .BoundGenericFunction:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: true)
        case .Subscript:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: false, extraName: "", extraIndex: -1, overwriteName: "subscript")
        case .Macro:
            if node.numberOfChildren == 3 {
                return try printEntity(
                    entity: node,
                    depth: depth,
                    asPrefixContext: asPrefixContext,
                    typePrinting: .withColon,
                    hasName: true
                )
            } else {
                return try printEntity(
                    entity: node,
                    depth: depth,
                    asPrefixContext: asPrefixContext,
                    typePrinting: .functionStyle,
                    hasName: true
                )
            }
        case .AccessorAttachedMacroExpansion:
            let macro = self.nodeToString(root: node.getChild(2))
            let extraName = "accessor macro @\(macro) expansion #"
            let extraIndex = Int((node.getChild(3).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
        case .FreestandingMacroExpansion:
            let extraName = "freestanding macro expansion #"
            let extraIndex = Int((node.getChild(2).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
        case .MacroExpansionLoc:
            for i in 0..<node.numberOfChildren {
                switch i {
                case 0:
                    printer("module ")
                case 1:
                    printer(" file ")
                case 2:
                    printer(" line ")
                case 3:
                    printer(" column ")
                default:
                    break
                }
                try printNode(node.children(i), depth: depth + 1)
            }
        case .MemberAttributeAttachedMacroExpansion:
            let macro = self.nodeToString(root: node.getChild(2))
            let extraName = "member attribute macro @\(macro) expansion #"
            let extraIndex = Int((node.getChild(3).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
        case .MemberAttachedMacroExpansion:
            let macro = self.nodeToString(root: node.getChild(2))
            let extraName = "member macro @\(macro) expansion #"
            let extraIndex = Int((node.getChild(3).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
        case .PeerAttachedMacroExpansion:
            let macro = self.nodeToString(root: node.getChild(2))
            let extraName = "peer macro @\(macro) expansion #"
            let extraIndex = Int((node.getChild(3).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
        case .ConformanceAttachedMacroExpansion:
            let macro = self.nodeToString(root: node.getChild(2))
            let extraName = "conformance macro @\(macro) expansion #"
            let extraIndex = Int((node.getChild(3).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
            
        case .ExtensionAttachedMacroExpansion:
            let macro = self.nodeToString(root: node.getChild(2))
            let extraName = "extension macro @\(macro) expansion #"
            let extraIndex = Int((node.getChild(3).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
        case .MacroExpansionUniqueName:
            let extraName = "unique name #"
            let extraIndex = Int((node.getChild(2).index ?? 0) + 1)
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true,
                extraName: extraName,
                extraIndex: extraIndex
            )
            
        case .GenericTypeParamDecl:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: true)
        case .ExplicitClosure:
            let typePrinting: TypePrinting = options.contains(.showFunctionArgumentTypes) ? .functionStyle : .noType
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: typePrinting, hasName: false, extraName: "closure #", extraIndex: Int(node.children(1).index.or(0)) + 1)
            
        case .ImplicitClosure:
            let typePrinting: TypePrinting = options.contains(.showFunctionArgumentTypes) ? .functionStyle : .noType
            return try printEntity(entity: node,
                                   depth: depth,
                                   asPrefixContext: asPrefixContext,
                                   typePrinting: typePrinting,
                                   hasName: false,
                                   extraName: "implicit closure #",
                                   extraIndex: Int(node.children(1).index.or(0)) + 1)
        case .Global:
            try printChildren(node, depth: depth)
        case .Suffix:
            if options.contains(.displayUnmangledSuffix) {
                printer(" with unmangled suffix " + self.quoted(text: node.text))
            }
        case .Initializer:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: false,
                extraName: "variable initialization expression"
            )
        case .PropertyWrapperBackingInitializer:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: false,
                extraName: "property wrapper backing initializer"
            )
        case .DefaultArgumentInitializer:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: false,
                extraName: "default argument ",
                extraIndex: node.children(1).index.flatMap(Int.init).or(0)
            )
        case .DeclContext:
            try printNode(node.children(0), depth: depth + 1)
        case .Type:
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMangling:
            if node.children(0).kind == .LabelList {
                try printFunctionType(
                    labelList: node.children(0),
                    type: node.children(1).children(0),
                    depth: depth
                )
            } else {
                try printNode(node.children(0), depth: depth + 1)
            }
        case .Class,
                .Structure,
                .Enum,
                .Protocol,
                .TypeAlias,
                .OtherNominalType:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .noType,
                hasName: true
            )
        case .LocalDeclName:
            try printNode(node.children(1), depth: depth + 1)
            if options.contains(.displayLocalNameContexts) {
                printer(" #\(node.children(0).index.or(0) + 1)")
            }
        case .PrivateDeclName:
            if node.numberOfChildren > 1 {
                if options.contains(.showPrivateDiscriminators) {
                    printer("(")
                }
                try printNode(node.children(1), depth: depth + 1)
                
                if options.contains(.showPrivateDiscriminators) {
                    printer(" in " + node.children(0).text + ")")
                }
            } else {
                if options.contains(.showPrivateDiscriminators) {
                    printer("(in " + node.children(0).text + ")")
                }
            }
        case .RelatedEntityDeclName:
            printer("related decl '" + node.children(0).text + "' for ")
            try printNode(node.children(1), depth: depth + 1)
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
            try printFunctionType(type: node, depth: depth)
        case .ClangType:
            printer(node.text)
        case .ArgumentTuple:
            try printFunctionParameters(
                parameterType: node,
                depth: depth,
                showTypes: options.contains(.showFunctionArgumentTypes)
            )
        case .Tuple:
            printer("(")
            try printChildren(node, depth: depth, separator: ", ")
            printer(")")
        case .TupleElement:
            if let label = node.childIf(.TupleElementName) {
                printer(label.text + ": ")
            }
            
            if let type = node.childIf(.Type) {
                try printNode(type, depth: depth + 1)
            } else {
                assertionFailure("malformed .TupleElement")
            }
            
            if node.childIf(.VariadicMarker) != nil {
                printer("...")
            }
        case .TupleElementName:
            printer(node.text + ": ")
        case .Pack:
            printer("Pack{")
            try printChildren(node, depth: depth, separator: ", ")
            printer("}")
        case .SILPackDirect,
                .SILPackIndirect:
            printer(node.kind == .SILPackDirect ? "@direct" : "@indirect")
            printer(" Pack{")
            try printChildren(node, depth: depth, separator: ", ")
            printer("}")
        case .PackExpansion:
            printer("repeat ")
            try printNode(node.children(0), depth: depth + 1)
        case .PackElement:
            printer("/* level: " + node.children(1).index.or(0).description + " */ ")
            printer("each ")
            try printNode(node.children(0), depth: depth + 1)
        case .PackElementLevel:
            throw SwiftDemangleError.nodePrinterError(description: "should be handled in Node.Kind.PackElement", nodeDebugDescription: node.debugDescription)
        case .ReturnType:
            if node.copyOfChildren.isEmpty {
                printer(" -> " + node.text)
            } else {
                printer(" -> ")
                try printChildren(node, depth: depth)
            }
        case .RetroactiveConformance:
            if node.numberOfChildren != 2 {
                return nil
            }
            
            printer("retroactive @ ")
            try printNode(node.children(0), depth: depth + 1)
            try printNode(node.children(1), depth: depth + 1)
        case .Weak:
            printer(ReferenceOwnership.weak.rawValue + " ")
            try printNode(node.children(0), depth: depth + 1)
        case .Unowned:
            printer(ReferenceOwnership.unowned.rawValue + " ")
            try printNode(node.children(0), depth: depth + 1)
        case .Unmanaged:
            printer(ReferenceOwnership.unmanaged.rawValue + " ")
            try printNode(node.children(0), depth: depth + 1)
        case .InOut:
            printer("inout ")
            try printNode(node.children(0), depth: depth + 1)
        case .Isolated:
            printer("isolated ")
            try printNode(node.children(0), depth: depth + 1)
        case .Sending:
            printer("sending ")
            try printNode(node.children(0), depth: depth + 1)
        case .Shared:
            printer("__shared ")
            try printNode(node.children(0), depth: depth + 1)
        case .Owned:
            printer("__owned ")
            try printNode(node.children(0), depth: depth + 1)
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
            try printSpecializationPrefix(node: node, description:  "function signature specialization", depth: depth)
        case .GenericPartialSpecialization:
            try printSpecializationPrefix(node: node, description: "generic partial specialization", depth: depth, paramPrefix: "Signature = ")
        case .GenericPartialSpecializationNotReAbstracted:
            try printSpecializationPrefix(node: node, description: "generic not-reabstracted partial specialization", depth: depth, paramPrefix: "Signature = ")
        case .GenericSpecialization,
                .GenericSpecializationInResilienceDomain:
            try printSpecializationPrefix(node: node, description: "generic specialization", depth: depth)
        case .GenericSpecializationPrespecialized:
            try printSpecializationPrefix(node: node, description: "generic pre-specialization", depth: depth)
        case .GenericSpecializationNotReAbstracted:
            try printSpecializationPrefix(node: node, description: "generic not re-abstracted specialization", depth: depth)
        case .InlinedGenericFunction:
            try printSpecializationPrefix(node: node, description: "inlined generic function", depth: depth)
        case .IsSerialized:
            printer("serialized")
        case .DroppedArgument:
            printer("param\(node.index.or(0).description)-removed")
        case .GenericSpecializationParam:
            try printNode(node.children(0), depth: depth + 1)
            for (offset, node) in node.copyOfChildren.enumerated() where offset > 0 {
                if offset == 1 {
                    printer(" with ")
                } else {
                    printer(" and ")
                }
                try printNode(node, depth: depth + 1)
            }
        case .FunctionSignatureSpecializationReturn,
                .FunctionSignatureSpecializationParam:
            throw SwiftDemangleError.nodePrinterError(description: "should be handled in printSpecializationPrefix", nodeDebugDescription: node.debugDescription)
        case .FunctionSignatureSpecializationParamPayload:
            if let demangleName = try node.text.demangleSymbolAsString(with: .defaultOptions).emptyToNil() {
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
                    case .InOutToOut:
                        printer("InOut Converted to Out")
                    case .ConstantPropKeyPath:
                        printer("Constant Propagated KeyPath")
                    }
                }
                if !kind.optionSet.isEmpty {
                    throw SwiftDemangleError.nodePrinterError(description: "option sets should have been handled earlier", nodeDebugDescription: node.debugDescription)
                }
            }
        case .SpecializationPassID:
            printer(node.index.or(0).description)
        case .BuiltinTypeName:
            printer(node.text)
        case .BuiltinTupleType:
            printer("Builtin.TheTupleType")
        case .BuiltinFixedArray:
            printer("Builtin.FixedArray<")
            try printNode(node.children(0), depth: depth + 1)
            printer(", ")
            try printNode(node.children(1), depth: depth + 1)
            printer(">")
        case .Number:
            printer(node.index.or(0).description)
        case .InfixOperator:
            printer(node.text + " infix")
        case .PrefixOperator:
            printer(node.text + " prefix")
        case .PostfixOperator:
            printer(node.text + " postfix")
        case .PreambleAttachedMacroExpansion:
            return nil
        case .LazyProtocolWitnessTableAccessor:
            printer("lazy protocol witness table accessor for type ")
            try printNode(node.children(0), depth: depth + 1)
            printer(" and conformance ")
            try printNode(node.children(1), depth: depth + 1)
        case .LazyProtocolWitnessTableCacheVariable:
            printer("lazy protocol witness table cache variable for type ")
            try printNode(node.children(0), depth: depth + 1)
            printer(" and conformance ")
            try printNode(node.children(1), depth: depth + 1)
        case .ProtocolSelfConformanceWitnessTable:
            printer("protocol self-conformance witness table for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolWitnessTableAccessor:
            printer("protocol witness table accessor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolWitnessTable:
            printer("protocol witness table for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolWitnessTablePattern:
            printer("protocol witness table pattern for ")
            try printNode(node.children(0), depth: depth + 1)
        case .GenericProtocolWitnessTable:
            printer("generic protocol witness table for ")
            try printNode(node.children(0), depth: depth + 1)
        case .GenericProtocolWitnessTableInstantiationFunction:
            printer("instantiation function for generic protocol witness table for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ResilientProtocolWitnessTable:
            printer("resilient protocol witness table for ")
            try printNode(node.children(0), depth: depth + 1)
        case .VTableThunk:
            printer("vtable thunk for ")
            try printNode(node.children(1), depth: depth + 1)
            printer(" dispatching to ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolSelfConformanceWitness:
            printer("protocol self-conformance witness for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolWitness:
            printer("protocol witness for ")
            try printNode(node.children(1), depth: depth + 1)
            printer(" in conformance ")
            try printNode(node.children(0), depth: depth + 1)
        case .PartialApplyForwarder:
            if options.contains(.shortenPartialApply) {
                printer("partial apply")
            } else {
                printer("partial apply forwarder")
            }
            if node.copyOfChildren.isNotEmpty {
                printer(" for ")
                try printChildren(node, depth: depth)
            }
        case .PartialApplyObjCForwarder:
            if options.contains(.shortenPartialApply) {
                printer("partial apply")
            } else {
                printer("partial apply ObjC forwarder")
            }
            if node.copyOfChildren.isNotEmpty {
                printer(" for ")
                try printChildren(node, depth: depth)
            }
        case .KeyPathGetterThunkHelper,
                .KeyPathSetterThunkHelper:
            if node.kind == .KeyPathGetterThunkHelper {
                printer("key path getter for ")
            } else {
                printer("key path setter for ")
            }
            
            try printNode(node.children(0), depth: depth + 1)
            printer(" : ")
            for child in node.copyOfChildren.dropFirst() {
                if child.kind == .IsSerialized {
                    printer(", ")
                }
                try printNode(child, depth: depth + 1)
            }
        case .KeyPathEqualsThunkHelper,
                .KeyPathHashThunkHelper:
            printer("key path index " + (node.kind == Node.Kind.KeyPathEqualsThunkHelper ? "equality" : "hash") + " operator for ")
            
            var lastChildIndex = node.copyOfChildren.endIndex
            var lastChild = node.children(lastChildIndex)
            if lastChild.kind == .IsSerialized {
                lastChildIndex -= 1
                lastChild = node.children(lastChildIndex)
            }
            
            if lastChild.kind == .DependentGenericSignature {
                try printNode(lastChild, depth: depth + 1)
                lastChildIndex -= 1
            }
            
            printer("(")
            for index in 0...lastChildIndex where index != 0 {
                printer(", ")
                try printNode(node.children(index), depth: depth + 1)
            }
            printer(")")
        case .FieldOffset:
            try printNode(node.children(0), depth: depth + 1) // directness
            printer("field offset for ")
            try printNode(node.children(1), depth: depth + 1)
        case .EnumCase:
            printer("enum case for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ReabstractionThunk,
                .ReabstractionThunkHelper:
            if options.contains(.shortenThunk) {
                printer("thunk for ")
                try printNode(node.children(node.copyOfChildren.endIndex - 1), depth: depth + 1)
                return nil
            }
            printer("reabstraction thunk ")
            if node.kind == .ReabstractionThunkHelper {
                printer("helper ")
            }
            var children = node.copyOfChildren
            if children.count == 3 {
                try printNode(children.removeFirst(), depth: depth + 1)
                printer(" ")
            }
            printer("from ")
            try printNode(children[1], depth: depth + 1)
            printer(" to ")
            try printNode(children[0], depth: depth + 1)
        case .ReabstractionThunkHelperWithSelf:
            printer("reabstraction thunk ")
            var children = node.copyOfChildren
            if (children.count == 4) {
                try printNode(children.removeFirst(), depth: depth + 1)
                printer(" ")
            }
            printer("from ")
            try printNode(children[2], depth: depth + 1)
            printer(" to ")
            try printNode(children[1], depth: depth + 1)
            printer(" self ")
            try printNode(children[0], depth: depth + 1)
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
        case .DistributedThunk:
            if options.contains(.shortenThunk) == false {
                printer("distributed thunk ")
            }
        case .DistributedAccessor:
            if options.contains(.shortenThunk) == false {
                printer("distributed accessor for ")
            }
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
            try printNode(node.children(0), depth: depth + 1)
        case .Metaclass:
            printer("metaclass for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolSelfConformanceDescriptor:
            printer("protocol self-conformance descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolConformanceDescriptor:
            printer("protocol conformance descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolConformanceDescriptorRecord:
            printer("protocol conformance descriptor runtime record for ")
            try printNode(node.getChild(0), depth: depth + 1);
        case .ProtocolDescriptor:
            printer("protocol descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ProtocolDescriptorRecord:
            printer("protocol descriptor runtime record for ")
            try printNode(node.getChild(0), depth: depth + 1)
        case .ProtocolRequirementsBaseDescriptor:
            printer("protocol requirements base descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .FullTypeMetadata:
            printer("full type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadata:
            printer("type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataAccessFunction:
            printer("type metadata accessor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataInstantiationCache:
            printer("type metadata instantiation cache for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataInstantiationFunction:
            printer("type metadata instantiation function for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataSingletonInitializationCache:
            printer("type metadata singleton initialization cache for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataCompletionFunction:
            printer("type metadata completion function for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataDemanglingCache:
            printer("demangling cache variable for type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .TypeMetadataLazyCache:
            printer("lazy cache variable for type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .AssociatedConformanceDescriptor:
            printer("associated conformance descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
            printer(".")
            try printNode(node.children(1), depth: depth + 1)
            printer(": ")
            try printNode(node.children(2), depth: depth + 1)
        case .DefaultAssociatedConformanceAccessor:
            printer("default associated conformance accessor for ")
            try printNode(node.children(0), depth: depth + 1)
            printer(".")
            try printNode(node.children(1), depth: depth + 1)
            printer(": ")
            try printNode(node.children(2), depth: depth + 1)
        case .AssociatedTypeDescriptor:
            printer("associated type descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .AssociatedTypeMetadataAccessor:
            printer("associated type metadata accessor for ")
            try printNode(node.children(1), depth: depth + 1)
            printer(" in ")
            try printNode(node.children(0), depth: depth + 1)
        case .BaseConformanceDescriptor:
            printer("base conformance descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
            printer(": ")
            try printNode(node.children(1), depth: depth + 1)
        case .DefaultAssociatedTypeMetadataAccessor:
            printer("default associated type metadata accessor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .AssociatedTypeWitnessTableAccessor:
            printer("associated type witness table accessor for ")
            try printNode(node.children(1), depth: depth + 1)
            printer(" : ")
            try printNode(node.children(2), depth: depth + 1)
            printer(" in ")
            try printNode(node.children(0), depth: depth + 1)
        case .BaseWitnessTableAccessor:
            printer("base witness table accessor for ")
            try printNode(node.children(1), depth: depth + 1)
            printer(" in ")
            try printNode(node.children(0), depth: depth + 1)
        case .BodyAttachedMacroExpansion:
            break
        case .ClassMetadataBaseOffset:
            printer("class metadata base offset for ")
            try printNode(node.children(0), depth: depth + 1)
        case .PropertyDescriptor:
            printer("property descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .NominalTypeDescriptor:
            printer("nominal type descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .NominalTypeDescriptorRecord:
            printer("nominal type descriptor runtime record for ")
            try printNode(node.getChild(0), depth: depth + 1)
        case .OpaqueTypeDescriptor:
            printer("opaque type descriptor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .OpaqueTypeDescriptorRecord:
            printer("opaque type descriptor runtime record for ")
            try printNode(node.getChild(0), depth: depth + 1);
        case .OpaqueTypeDescriptorAccessor:
            printer("opaque type descriptor accessor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .OpaqueTypeDescriptorAccessorImpl:
            printer("opaque type descriptor accessor impl for ")
            try printNode(node.children(0), depth: depth + 1)
        case .OpaqueTypeDescriptorAccessorKey:
            printer("opaque type descriptor accessor key for ")
            try printNode(node.children(0), depth: depth + 1)
        case .OpaqueTypeDescriptorAccessorVar:
            printer("opaque type descriptor accessor var for ")
            try printNode(node.children(0), depth: depth + 1)
        case .CoroutineContinuationPrototype:
            printer("coroutine continuation prototype for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ValueWitness:
            printer(node.children(0).valueWitnessKind!.name)
            if options.contains(.shortenValueWitness) {
                printer(" for ")
            } else {
                printer(" value witness for ")
            }
            try printNode(node.children(1), depth: depth + 1)
        case .ValueWitnessTable:
            printer("value witness table for ")
            try printNode(node.children(0), depth: depth + 1)
        case .BoundGenericClass,
                .BoundGenericStructure,
                .BoundGenericEnum,
                .BoundGenericProtocol,
                .BoundGenericOtherNominalType,
                .BoundGenericTypeAlias:
            try printBoundGeneric(node: node, depth: depth)
        case .DynamicSelf:
            printer("Self")
            
        case .SILBoxType:
            printer("@box ")
            try printNode(node.children(0), depth: depth + 1)
        case .Metatype:
            var index = 0
            if node.numberOfChildren == 2 {
                let repr = node.children(index)
                try printNode(repr, depth: depth + 1)
                printer(" ")
                index += 1
            }
            let type = node.children(index).children(0)
            try printWithParens(type, depth: depth)
            if type.isExistentialType {
                printer(".Protocol")
            } else {
                printer(".Type")
            }
        case .ExistentialMetatype:
            var index = 0
            if node.numberOfChildren == 2 {
                let repr = node.children(index)
                try printNode(repr, depth: depth + 1)
                printer(" ")
                index += 1
            }
            let type = node.children(index)
            try printNode(type, depth: depth + 1)
            printer(".Type")
        case .MetatypeRepresentation:
            printer(node.text)
        case .ConstrainedExistential:
            printer("any ")
            try printNode(node.getChild(0), depth: depth + 1)
            printer("<")
            try printNode(node.getChild(1), depth: depth + 1)
            printer(">")
        case .ConstrainedExistentialRequirementList:
            try printChildren(node, depth: depth, separator: ", ")
        case .ConstrainedExistentialSelf:
            printer("Self")
        case .AssociatedTypeRef:
            try printNode(node.children(0), depth: depth + 1)
            printer("." + node.children(1).text)
        case .ProtocolList:
            guard let typeList = node.copyOfChildren.first else {
                return nil
            }
            if typeList.numberOfChildren == 0 {
                printer("Any")
            } else {
                try printChildren(typeList, depth: depth, separator: " & ")
            }
        case .ProtocolListWithClass:
            if node.numberOfChildren < 2 {
                return nil
            }
            let protocols = node.children(0)
            let superclass = node.children(1)
            try printNode(superclass, depth: depth + 1)
            printer(" & ")
            if protocols.copyOfChildren.isEmpty {
                return nil
            }
            let typeList = protocols.children(0)
            try printChildren(typeList, depth: depth, separator: " & ")
        case .ProtocolListWithAnyObject:
            if node.copyOfChildren.isEmpty {
                return nil
            }
            let protocols = node.children(0)
            if protocols.copyOfChildren.isEmpty {
                return nil
            }
            let typeList = protocols.children(0)
            if typeList.numberOfChildren > 0 {
                try printChildren(typeList, depth: depth, separator: " & ")
                printer(" & ")
            }
            if options.contains([.qualifyEntities, .displayStdlibModule]) {
                printer(.STDLIB_NAME + ".")
            }
            printer("AnyObject")
        case .AssociatedType:
            break
        case .OwningAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "owningAddressor")
        case .OwningMutableAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "owningMutableAddressor")
        case .NativeOwningAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "nativeOwningAddressor")
        case .NativeOwningMutableAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "nativeOwningMutableAddressor")
        case .NativePinningAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "nativePinningAddressor")
        case .NativePinningMutableAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "nativePinningMutableAddressor")
        case .UnsafeAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "unsafeAddressor")
        case .UnsafeMutableAddressor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "unsafeMutableAddressor")
        case .GlobalGetter:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "getter")
        case .Getter:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "getter")
        case .Setter:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "setter")
        case .MaterializeForSet:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "materializeForSet")
        case .WillSet:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "willset")
        case .DidSet:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "didset")
        case .ReadAccessor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "read")
        case .Read2Accessor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "read2")
        case .ModifyAccessor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "modify")
        case .Modify2Accessor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "modify2")
        case .InitAccessor:
            return try printAbstractStorage(node: node.children(0), depth: depth, asPrefixContext: asPrefixContext, extraName: "init")
        case .Allocator:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: false, extraName: node.children(0).isClassType ? "__allocating_init" : "init")
        case .Constructor:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: node.numberOfChildren > 2, extraName: "init")
        case .Destructor:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "deinit")
        case .Deallocator:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: node.children(0).isClassType ? "__deallocating_deinit" : "deinit")
        case .IsolatedDeallocator:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: node.children(0).isClassType ? "__isolated_deallocating_deinit" : "deinit")
        case .IVarInitializer:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "__ivar_initializer")
        case .IVarDestroyer:
            return try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "__ivar_destroyer")
        case .ProtocolConformance:
            let (child0, child1, child2) = (node.children(0), node.children(1), node.children(2))
            if node.numberOfChildren == 4 {
                // TODO: check if this is correct
                printer("property behavior storage of ")
                try printNode(child2, depth: depth + 1)
                printer(" in ")
                try printNode(child0, depth: depth + 1)
                printer(" : ")
                try printNode(child1, depth: depth + 1)
            } else {
                try printNode(child0, depth: depth + 1)
                if options.contains(.displayProtocolConformances) {
                    printer(" : ")
                    try printNode(child1, depth: depth + 1)
                    printer(" in ")
                    try printNode(child2, depth: depth + 1)
                }
            }
        case .TypeList:
            try printChildren(node, depth: depth)
        case .LabelList:
            break
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
            }
        case .ImplEscaping:
            printer("@escaping")
        case .ImplErasedIsolation:
            printer("@isolated(any)")
        case .ImplCoroutineKind:
            guard let text = node.text.emptyToNil() else {
                break
            }
            printer(text + " ")
        case .ImplSendingResult:
            printer("sending")
        case .ImplConvention:
            printerText(node)
        case .ImplFunctionConventionName:
            assert(false, "Already handled in ImplFunctionConvention")
            printer("@error ")
            try printChildren(node, depth: depth, separator: " ")
        case .ImplYield:
            printer("@yields ")
            try printChildren(node, depth: depth, separator: " ")
        case .ImplParameter,
                .ImplResult:
            // Children: `convention, differentiability?, type`
            // Print convention.
            try printNode(node.children(0), depth: depth + 1)
            printer(" ")
            // Print differentiability, if it exists.
            if node.numberOfChildren == 3 {
                try printNode(node.children(1), depth: depth + 1)
            }
            // Print type.
            try printNode(node.lastChild, depth: depth + 1)
        case .ImplFunctionType:
            try printImplFunctionType(function: node, depth: depth)
        case .ImplInvocationSubstitutions:
            printer("for <")
            try printChildren(node.children(0), depth: depth, separator: ", ")
            printer(">")
        case .ImplPatternSubstitutions:
            printer("@substituted ")
            try printNode(node.children(0), depth: depth + 1)
            printer(" for <")
            try printChildren(node.children(1), depth: depth, separator: ", ")
            printer(">")
        case .ErrorType:
            printer("<ERROR TYPE>")
        case .DependentPseudogenericSignature,
                .DependentGenericSignature:
            printGenericSignature(node: node, depth: depth)
        case .DependentGenericParamCount,
                .DependentGenericParamPackMarker,
                .DependentGenericParamValueMarker:
            throw SwiftDemangleError.nodePrinterError(description: "should be printed as a child of a DependentGenericSignature", nodeDebugDescription: node.debugDescription)
        case .DependentGenericConformanceRequirement:
            let type = node.children(0)
            let reqt = node.children(1)
            try printNode(type, depth: depth + 1)
            printer(": ")
            try printNode(reqt, depth: depth + 1)
        case .DependentGenericLayoutRequirement:
            let type = node.children(0)
            let layout = node.children(1)
            
            try printNode(type, depth: depth + 1)
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
                try printNode(node.children(2), depth: depth + 1)
                if node.numberOfChildren > 3 {
                    printer(", ")
                    try printNode(node.children(3), depth: depth + 1)
                }
                printer(")")
            }
        case .DependentGenericSameTypeRequirement:
            let first = node.children(0)
            let second = node.children(1)
            try printNode(first, depth: depth + 1)
            printer(" == ")
            try printNode(second, depth: depth + 1)
        case .DependentGenericSameShapeRequirement:
            let first = node.children(0)
            let second = node.children(1)
            try printNode(first, depth: depth + 1)
            printer(".shape == ")
            try printNode(second, depth: depth + 1)
            printer(".shape")
        case .DependentGenericParamType:
            let index = node.children(1).index.or(0)
            let depth = node.children(0).index.or(0)
            printer(options.genericParameterName(depth: UInt64(depth), index: UInt64(index)))
        case .DependentGenericType:
            let signature = node.children(0)
            let dependentType = node.children(1)
            try printNode(signature, depth: depth + 1)
            if dependentType.isNeedSpaceBeforeType {
                printer(" ")
            }
            try printNode(dependentType, depth: depth + 1)
        case .DependentMemberType:
            let base = node.children(0)
            try printNode(base, depth: depth + 1)
            printer(".")
            let associatedType = node.children(1)
            try printNode(associatedType, depth: depth + 1)
        case .DependentAssociatedTypeRef:
            if node.numberOfChildren > 1 {
                try printNode(node.children(1), depth: depth + 1)
                printer(".")
            }
            try printNode(node.children(0), depth: depth + 1)
        case .ReflectionMetadataBuiltinDescriptor:
            printer("reflection metadata builtin descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .ReflectionMetadataFieldDescriptor:
            printer("reflection metadata field descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .ReflectionMetadataAssocTypeDescriptor:
            printer("reflection metadata associated type descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .ReflectionMetadataSuperclassDescriptor:
            printer("reflection metadata superclass descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .AsyncAnnotation:
            printer(" async ")
        case .ThrowsAnnotation:
            printer(" throws ")
        case .TypedThrowsAnnotation:
            printer(" throws(")
            if node.numberOfChildren == 1 {
                try printNode(node.children(0), depth: depth + 1)
            }
            printer(")")
        case .EmptyList:
            printer(" empty-list ")
        case .FirstElementMarker:
            printer(" first-element-marker ")
        case .VariadicMarker:
            printer(" variadic-marker ")
        case .SILBoxTypeWithLayout:
            assert(node.numberOfChildren == 1 || node.numberOfChildren == 3)
            let layout = node.children(0)
            assert(layout.kind == .SILBoxLayout)
            var genericArgs: Node?
            if node.numberOfChildren == 3 {
                let signature = node.children(1)
                assert(signature.kind == .DependentGenericSignature)
                genericArgs = node.children(2)
                assert(genericArgs?.kind == .TypeList)
                try printNode(signature, depth: depth + 1)
                printer(" ")
            }
            try printNode(layout, depth: depth + 1)
            if let args = genericArgs {
                printer(" <")
                for (index, child) in args.copyOfChildren.enumerated() {
                    if index > 0 {
                        printer(", ")
                    }
                    try printNode(child, depth: depth + 1)
                }
                printer(">")
            }
        case .SILBoxLayout:
            printer("{")
            for (index, child) in node.copyOfChildren.enumerated() {
                if index > 0 {
                    printer(",")
                }
                printer(" ")
                try printNode(child, depth: depth + 1)
            }
            printer(" }")
        case .SILBoxImmutableField,
                .SILBoxMutableField:
            printer(node.kind == .SILBoxImmutableField ? "let " : "var ")
            assert(node.numberOfChildren == 1 && node.children(0).kind == .Type)
            try printNode(node.children(0), depth: depth + 1)
        case .AssocTypePath:
            try printChildren(node, depth: depth, separator: ".")
        case .ModuleDescriptor:
            printer("module descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .AnonymousDescriptor:
            printer("anonymous descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .ExtensionDescriptor:
            printer("extension descriptor ")
            try printNode(node.children(0), depth: depth + 1)
        case .AssociatedTypeGenericParamRef:
            printer("generic parameter reference for associated type ")
            try printChildren(node, depth: depth)
        case .AnyProtocolConformanceList:
            try printChildren(node, depth: depth)
        case .ConcreteProtocolConformance:
            printer("concrete protocol conformance ")
            if let index = node.index {
                printer("#" + index.description + " ")
            }
            try printChildren(node, depth: depth)
        case .PackProtocolConformance:
            printer("pack protocol conformance ")
            try printChildren(node, depth: depth)
        case .DependentAssociatedConformance:
            printer("dependent associated conformance ")
            try printChildren(node, depth: depth)
        case .DependentProtocolConformanceAssociated:
            printer("dependent associated protocol conformance ")
            printOptionalIndex(node.children(2))
            try printNode(node.children(0), depth: depth + 1)
            try printNode(node.children(1), depth: depth + 1)
        case .DependentProtocolConformanceInherited:
            printer("dependent inherited protocol conformance ")
            printOptionalIndex(node.children(2))
            try printNode(node.children(0), depth: depth + 1)
            try printNode(node.children(1), depth: depth + 1)
        case .DependentProtocolConformanceRoot:
            printer("dependent root protocol conformance ")
            printOptionalIndex(node.children(2))
            try printNode(node.children(0), depth: depth + 1)
            try printNode(node.children(1), depth: depth + 1)
        case .ProtocolConformanceRefInTypeModule:
            printer("protocol conformance ref (type's module) ")
            try printChildren(node, depth: depth)
        case .ProtocolConformanceRefInProtocolModule:
            printer("protocol conformance ref (protocol's module) ")
            try printChildren(node, depth: depth)
        case .ProtocolConformanceRefInOtherModule:
            printer("protocol conformance ref (retroactive) ")
            try printChildren(node, depth: depth)
        case .SugaredOptional:
            try printWithParens(node.children(0), depth: depth)
            printer("?")
        case .SugaredArray:
            printer("[")
            try printNode(node.children(0), depth: depth + 1)
            printer("]")
        case .SugaredDictionary:
            printer("[")
            try printNode(node.children(0), depth: depth + 1)
            printer(" : ")
            try printNode(node.children(1), depth: depth + 1)
            printer("]")
        case .SugaredParen:
            printer("(")
            try printNode(node.children(0), depth: depth + 1)
            printer(")")
        case .OpaqueReturnType:
            printer("some")
        case .OpaqueReturnTypeOf:
            printer("<<opaque return type of ")
            try printChildren(node, depth: depth)
            printer(">>")
        case .OpaqueType:
            try printNode(node.children(0), depth: depth + 1)
            printer(".")
            try printNode(node.children(1), depth: depth + 1)
        case .AccessorFunctionReference:
            printer("accessor function at " + node.index.or(0).description)
        case .CanonicalSpecializedGenericMetaclass:
            printer("specialized generic metaclass for ")
            try printNode(node.children(0), depth: depth + 1)
        case .CanonicalSpecializedGenericTypeMetadataAccessFunction:
            printer("canonical specialized generic type metadata accessor for ")
            try printNode(node.children(0), depth: depth + 1)
        case .MetadataInstantiationCache:
            printer("metadata instantiation cache for ")
            try printNode(node.children(0), depth: depth + 1)
        case .NoncanonicalSpecializedGenericTypeMetadata:
            printer("noncanonical specialized generic type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .NoncanonicalSpecializedGenericTypeMetadataCache:
            printer("cache variable for noncanonical specialized generic type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .GlobalVariableOnceToken,
                .GlobalVariableOnceFunction:
            printer(node.kind == .GlobalVariableOnceToken
                    ? "one-time initialization token for "
                    : "one-time initialization function for ")
            try printNode(node.children(1), depth: depth + 1)
        case .GlobalVariableOnceDeclList:
            if node.numberOfChildren == 1 {
                try printNode(node.children(0), depth: depth + 1)
            } else {
                printer("(")
                try printChildren(node, depth: depth, separator: ", ")
                printer(")")
            }
        case .PredefinedObjCAsyncCompletionHandlerImpl:
            printer("predefined ")
            fallthrough
        case .ObjCAsyncCompletionHandlerImpl:
            printer("@objc completion handler block implementation for ")
            try printNode(node.children(0), depth: depth + 1)
            printer(" with result type ")
            try printNode(node.children(1), depth: depth + 1)
        case .CanonicalPrespecializedGenericTypeCachingOnceToken:
            printer("flag for loading of canonical specialized generic type metadata for ")
            try printNode(node.children(0), depth: depth + 1)
        case .ConcurrentFunctionType:
            printer("@Sendable ")
        case .GlobalActorFunctionType:
            if node.getNumChildren() > 0 {
                printer("@")
                try printNode(node.firstChild, depth: depth + 1)
                printer(" ")
            }
        case .IsolatedAnyFunctionType:
            printer("@isolated(any) ")
        case .SendingResultFunctionType:
            printer("sending ")
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
                    throw PrintingError.unexpectedCaseNonDifferentiable
                }
            }
            printer(" ")
        case .ImplParameterResultDifferentiability:
            if node.text.isEmpty == false {
                printer(node.text + " ")
            }
        case .ImplParameterSending:
            if node.text.isEmpty == false {
                printer(node.text + " ")
            }
        case .ImplFunctionAttribute:
            printer(node.text)
        case .ImplFunctionConvention:
            printer("@convention(")
            switch node.getNumChildren() {
            case 1:
                printer(node.firstChild.text)
            case 2:
                printer(node.firstChild.text + ", mangledCType: \"")
                try printNode(node.children(0), depth: depth + 1)
                printer("\"")
            default:
                assert(false, "Unexpected numChildren for ImplFunctionConvention")
            }
            printer(")")
        case .ImplErrorResult:
            printer("@error ")
            try printChildren(node, depth: depth, separator: " ")
        case .PropertyWrapperInitFromProjectedValue:
            try printEntity(entity: node, depth: depth, asPrefixContext: asPrefixContext, typePrinting: .noType, /*hasName*/hasName: false, extraName: "property wrapper init from projected value")
        case .ReabstractionThunkHelperWithGlobalActor:
            try printNode(node.getChild(0), depth: depth + 1)
            printer(" with global actor constraint ")
            try printNode(node.getChild(1), depth: depth + 1)
        case .AsyncFunctionPointer:
            printer("async function pointer to ")
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
            try printNode(funcKind, depth: depth + 1)
            printer(" of ")
            var optionalGenSig: Node?
            for index in 0..<prefixEndIndex {
                // The last node may be a generic signature. If so, print it later.
                if (index == prefixEndIndex - 1 && node.getChild(index).getKind() == .DependentGenericSignature) {
                    optionalGenSig = node.getChild(index)
                } else {
                    try printNode(node.getChild(index), depth: depth + 1)
                }
            }
            if options.contains(.shortenThunk) == false {      
                printer(" with respect to parameters ")
                try printNode(paramIndices, depth: depth + 1)
                printer(" and results ")
                try printNode(resultIndices, depth: depth + 1)
                if let optionalGenSig = optionalGenSig, options.contains(.displayWhereClauses) {
                    printer(" with ")
                    try printNode(optionalGenSig, depth: depth + 1)
                }
            }
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
        case .AutoDiffSelfReorderingReabstractionThunk:
            printer("autodiff self-reordering reabstraction thunk ")
            var childIt = 0
            let fromType = node.getChild(childIt.advancedAfter())
            let toType = node.getChild(childIt.advancedAfter())
            if options.contains(.shortenThunk) {
                printer("for ")
                try printNode(fromType, depth: depth + 1)
                break
            }
            let optionalGenSig: Node? = toType.kind == .DependentGenericSignature ? node.getChild(childIt.advancedAfter()) : nil
            printer("for ")
            try printNode(node.getChild(childIt.advancedAfter()), depth: depth + 1) // kind
            if let node = optionalGenSig {
                try printNode(node, depth: depth + 1)
                printer(" ")
            }
            printer(" from ")
            try printNode(fromType, depth: depth + 1)
            printer(" to ")
            try printNode(toType, depth: depth + 1)
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
            try printNode(kind, depth: depth + 1)
            printer(" from ")
            // Print the "from" thing.
            if (currentIndex == 0) {
                try printNode(node.getFirstChild(), depth: depth + 1) // the "from" type
            } else {
                if currentIndex > 0 {
                    for index in 0..<currentIndex { // the "from" global
                        try printNode(node.getChild(index), depth: depth + 1)
                    }
                }
            }
            if options.contains(.shortenThunk) {
                return nil
            }
            printer(" with respect to parameters ")
            try printNode(paramIndices, depth: depth + 1)
            printer(" and results ")
            try printNode(resultIndices, depth: depth + 1)
            printer(" to parameters ")
            try printNode(toParamIndices, depth: depth + 1)
            if currentIndex > 0 {
                printer(" of type ")
                try printNode(node.getChild(currentIndex), depth: depth + 1) // "to" type
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
                try printNode(node.children(idx), depth: depth + 1)
                idx += 1
            }
            idx += 1 // kind (handled earlier)
            printer(" with respect to parameters ")
            try printNode(node.getChild(idx), depth: depth + 1) // parameter indices
            idx += 1
            printer(" and results ")
            try printNode(node.getChild(idx), depth: depth + 1)
            idx += 1
            if idx < node.getNumChildren() {
                let genSig = node.getChild(idx)
                assert(genSig.getKind() == .DependentGenericSignature)
                printer(" with ")
                try printNode(genSig, depth: depth + 1)
            }
            return nil
        case .NoDerivative:
            printer("@noDerivative ")
            try printNode(node.getChild(0), depth: depth + 1)
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
                try printNode(node.getChild(0), depth: depth + 1)
                printer(")")
                printer(" await resume partial function for ")
            }
            return nil
        case .AsyncSuspendResumePartialFunction:
            if options.contains(.showAsyncResumePartial) {
                printer("(")
                try printNode(node.getChild(0), depth: depth + 1)
                printer(")")
                printer(" suspend resume partial function for ")
            }
            return nil
        case .AccessibleFunctionRecord:
            if options.contains(.shortenThunk) == false {
                printer("accessible function runtime record for ")
            }
        case .CompileTimeConst:
            printer("_const ")
            try printNode(node.getChild(0), depth: depth + 1)
        case .BackDeploymentThunk:
            if options.contains(.shortenThunk) == false {
                printer("back deployment thunk for ")
            }
        case .BackDeploymentFallback:
            printer("back deployment fallback for ")
        case .ExtendedExistentialTypeShape:
            // Printing the requirement signature is pretty useless if we
            // don't print `where` clauses.
            let savedOptions = options
            options.insert(.displayWhereClauses)
            
            let genSig: Node?
            let type: Node
            
            if node.getNumChildren() == 2 {
                genSig = node.getChild(1)
                type = node.getChild(2)
            } else {
                genSig = nil
                type = node.getChild(1)
            }
            
            printer("existential shape for ")
            if let genSig {
                try printNode(genSig, depth: depth + 1)
                printer(" ")
            }
            printer("any ")
            try printNode(type, depth: depth + 1)
            
            options = savedOptions
        case .Uniquable:
            printer("uniquable ")
            try printNode(node.getChild(0), depth: depth + 1)
        case .UniqueExtendedExistentialTypeShapeSymbolicReference:
            printer("unique existential shape symbolic reference 0x")
            printerHex(node.index)
        case .NonUniqueExtendedExistentialTypeShapeSymbolicReference:
            printer("non-unique existential shape symbolic reference 0x")
            printerHex(node.index)
        case .ObjectiveCProtocolSymbolicReference:
            printer("objective-c protocol symbolic reference 0x")
            printerHex(node.index)
        case .SymbolicExtendedExistentialType:
            let shape = node.getChild(0)
            if shape.getKind() == .UniqueExtendedExistentialTypeShapeSymbolicReference {
                printer("symbolic existential type (unique) 0x")
            } else {
                printer("symbolic existential type (non-unique) 0x")
            }
            printerHex(node.index)
            printer(" <")
            try printNode(node.getChild(1), depth: depth + 1)
            if node.getNumChildren() > 2 {
                printer(", ")
                try printNode(node.getChild(2), depth: depth  + 1)
            }
            printer(">")
        case .HasSymbolQuery:
            printer("#_hasSymbol query for ")
        case .OpaqueReturnTypeIndex:
            break
        case .OpaqueReturnTypeParent:
            break
        }
        return nil
    }
    
    @discardableResult
    private mutating func printEntity(entity: Node,
                                      depth: Int,
                                      asPrefixContext: Bool,
                                      typePrinting: TypePrinting,
                                      hasName: Bool,
                                      extraName: String? = nil,
                                      extraIndex: Int = -1,
                                      overwriteName: String? = nil) throws -> Node? {
        var entity = entity
        var typePrinting = typePrinting
        var extraIndex = extraIndex
        var extraName = extraName
        var genericFunctionTypeList: Node?
        if entity.kind == .BoundGenericFunction {
            genericFunctionTypeList = entity.children(1)
            entity = entity.children(0)
        }
        // Either we print the context in prefix form "<context>.<name>" or in
        // suffix form "<name> in <context>".
        var multiWordName = extraName?.contains(" ") ?? false
        // Also a local name (e.g. Mystruct #1) does not look good if its context is
        // printed in prefix form.
        let localName = hasName && entity.children(1).kind == .LocalDeclName
        if localName, options.contains(.displayLocalNameContexts) {
            multiWordName = true
        }
        if asPrefixContext && (typePrinting != .noType || multiWordName) {
            // If the context has a type to be printed, we can't use the prefix form.
            return entity
        }
        var postfixContext: Node?
        let context = entity.children(0)
        
        if printContext(context) {
            if multiWordName {
                // If the name contains some spaces we don't print the context now but
                // later in suffix form.
                postfixContext = context
            } else {
                let currentPosition = printText.count
                postfixContext = try printNode(context, depth: depth + 1, asPrefixContext: true)
                
                // Was the context printed as prefix?
                if printText.count != currentPosition {
                    printer(".")
                }
            }
        }
        if hasName || overwriteName.isNotEmpty {
            if let name = extraName?.emptyToNil(), multiWordName {
                printer(name)
                if extraIndex >= 0 {
                    printerIndex(extraIndex)
                }
                printer(" of ")
                extraName = ""
                extraIndex = -1
            }
            let currentPos = printText.count
            if let name = overwriteName?.emptyToNil() {
                printer(name)
            } else {
                let name = entity.children(1)
                if name.kind != .PrivateDeclName {
                    try printNode(name, depth: depth + 1)
                }
                if let privateName = entity.childIf(.PrivateDeclName) {
                    try printNode(privateName, depth: depth + 1)
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
                setInvalid()
                return nil
            }
            type = type.children(0)
            if typePrinting == .functionStyle {
                // We expect to see a function type here, but if we don't, use the colon.
                var t = type
                while t.kind == .DependentGenericType {
                    t = t.children(1).children(0)
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
                    try printEntityType(
                        entity: entity,
                        type: type,
                        genericFunctionTypeList: genericFunctionTypeList,
                        depth: depth
                    )
                }
            } else {
                assert(typePrinting == .functionStyle)
                if multiWordName || needSpaceBeforeType(type: type) {
                    printer(" ")
                }
                try printEntityType(
                    entity: entity,
                    type: type,
                    genericFunctionTypeList: genericFunctionTypeList,
                    depth: depth
                )
            }
        }
        
        if !asPrefixContext, let context = postfixContext, (!localName || options.contains(.displayLocalNameContexts)) {
            switch entity.kind {
            case .DefaultArgumentInitializer,
                    .Initializer,
                    .PropertyWrapperBackingInitializer,
                    .PropertyWrapperInitFromProjectedValue:
                printer(" of ")
            default:
                printer(" in ")
            }
            try printNode(context, depth: depth + 1)
            postfixContext = nil
        }
        return postfixContext
    }
    
    mutating func printEntityType(entity: Node, type: Node, genericFunctionTypeList: Node?, depth: Int) throws {
        let labelList = entity.childIf(.LabelList)
        var type = type
        if labelList != nil || genericFunctionTypeList != nil {
            if let node = genericFunctionTypeList {
                printer("<")
                try printChildren(node, depth: depth, separator: ", ")
                printer(">")
            }
            if type.kind == .DependentGenericType {
                if genericFunctionTypeList == nil {
                    try printNode(type.children(0), depth: depth + 1) // generic signature
                }
                let dependentType = type.children(1)
                if (needSpaceBeforeType(type: dependentType)) {
                    printer(" ")
                }
                type = dependentType.children(0)
            }
            
            try printFunctionType(labelList: labelList, type: type, depth: depth)
        } else {
            try printNode(type, depth: depth + 1)
        }
    }
    
    mutating func printChildren(nodes: [Node], depth: Int, separator: String? = nil) throws {
        for (offset, node) in nodes.enumerated() {
            try printNode(node, depth: depth + 1)
            if let separator = separator, offset > 0 {
                printer(separator)
            }
        }
    }
    
    mutating func printChildren(_ node: Node, depth: Int, separator: String? = nil) throws {
        try printChildren(nodes: node.copyOfChildren, depth: depth, separator: separator)
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
            if context.text.hasPrefix(.LLDB_EXPRESSIONS_MODULE_NAME_PREFIX) {
                return options.contains(.displayDebuggerGeneratedModule)
            }
        }
        return true
    }
    
    mutating func printFunctionType(labelList: Node? = nil, type: Node, depth: Int) throws {
        if type.numberOfChildren < 2 {
            setInvalid()
            return
        }
        
        func printConventionWithMangledCType(convention: String) throws {
            printer("@convention(" + convention)
            if type.children(0).kind == .ClangType {
                printer(", mangledCType: \"")
                try printNode(type.children(0), depth: depth + 1)
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
            try printConventionWithMangledCType(convention: "c")
        case .EscapingObjCBlock:
            printer("@escaping ")
            fallthrough
        case .ObjCBlock:
            try printConventionWithMangledCType(convention: "block")
        default:
            assertionFailure("Unhandled function type in printFunctionType!")
        }
        
        let argumentIndex = type.numberOfChildren - 2
        var startIndex: Int = 0
        var isSendable = false
        var isAsync = false
        var hasSendingResult = false
        var diffKind = MangledDifferentiabilityKind.nonDifferentiable
        if type.getChild(startIndex).kind == .ClangType {
            startIndex += 1
        }
        if type.children(startIndex).kind == .IsolatedAnyFunctionType {
            try printNode(type.children(startIndex), depth: depth + 1)
            startIndex += 1
        }
        if type.children(startIndex).kind == .GlobalActorFunctionType {
            try printNode(type.children(startIndex), depth: depth + 1)
            startIndex += 1
        }
        if type.children(startIndex).kind == .DifferentiableFunctionType {
            diffKind = type.children(startIndex).mangledDifferentiabilityKind ?? .nonDifferentiable
            startIndex += 1
        }
        var throwsAnnotation: Node?
        switch type.children(startIndex).kind {
        case .ThrowsAnnotation, .TypedThrowsAnnotation:
            throwsAnnotation = type.children(startIndex)
            startIndex += 1
        default:
            break
        }
        if type.children(startIndex).kind == .ConcurrentFunctionType {
            startIndex += 1
            isSendable = true
        }
        if type.children(startIndex).kind == .AsyncAnnotation {
            startIndex += 1
            isAsync = true
        }
        if type.children(startIndex).kind == .SendingResultFunctionType {
            startIndex += 1
            hasSendingResult = true
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
        
        try printFunctionParameters(labelList: labelList,
                                    parameterType: type.children(argumentIndex),
                                    depth: depth,
                                    showTypes: options.contains(.showFunctionArgumentTypes))
        
        if !options.contains(.showFunctionArgumentTypes) {
            return
        }
        
        if isAsync {
            printer(" async")
        }
        
        if let throwsAnnotation {
            try printNode(throwsAnnotation, depth: depth + 1)
        }
        printer(" -> ")

        if hasSendingResult {
            printer("sending ")
        }
        try printNode(type.children(argumentIndex + 1), depth: depth + 1)
    }
    
    mutating func printFunctionParameters(labelList: Node? = nil, parameterType: Node, depth: Int, showTypes: Bool) throws {
        if parameterType.kind != .ArgumentTuple {
            setInvalid()
            return
        }
        
        var parameters = parameterType.children(0)
        assert(parameters.kind == .Type)
        parameters = parameters.children(0)
        if parameters.kind != .Tuple {
            // only a single not-named parameter
            if showTypes {
                printer("(")
                try printNode(parameters, depth: depth + 1)
                printer(")")
            } else {
                printer("(_:)")
            }
            return
        }
        
        func getLabel(for param: Node, index: Int) -> String {
            guard let label = labelList?.children(index) else {
                assertionFailure()
                return "_"
            }
            assert(label.kind == .Identifier || label.kind == .FirstElementMarker)
            return label.kind == .Identifier ? label.text : "_"
        }
        
        let hasLabels: Bool
        if let numberOfChildren = labelList?.numberOfChildren {
            hasLabels = numberOfChildren > 0
        } else {
            hasLabels = false
        }
        
        printer("(")
        try parameters.copyOfChildren.interleave { (index, param) in
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
                try printNode(param, depth: depth + 1)
            }
        } betweenHandle: {
            guard showTypes else { return }
            self.printer(", ")
        }
        printer(")")
    }
    
    mutating func printSpecializationPrefix(node: Node, description: String, depth: Int, paramPrefix: String? = nil) throws {
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
        for child in node.copyOfChildren {
            switch child.kind {
            case .SpecializationPassID, .DroppedArgument:
                // We skip the SpecializationPassID since it does not contain any
                // information that is useful to our users.
                break
            case .IsSerialized:
                printer(separator)
                separator = ", "
                try printNode(child, depth: depth + 1)
            default:
                // Ignore empty specializations.
                if child.copyOfChildren.isNotEmpty {
                    printer(separator)
                    printer(paramPrefix ?? "")
                    separator = ", "
                    switch child.kind {
                    case .FunctionSignatureSpecializationParam:
                        printer("Arg[\(argumentNumber)] = ")
                        try printFunctionSigSpecializationParams(node: child, depth: depth)
                    case .FunctionSignatureSpecializationReturn:
                        printer("Return = ")
                        try printFunctionSigSpecializationParams(node: child, depth: depth)
                    default:
                        try printNode(child, depth: depth + 1)
                    }
                }
                argumentNumber += 1
            }
        }
        printer("> of ")
    }
    
    mutating func printFunctionSigSpecializationParams(node: Node, depth: Int) throws {
        var index = 0
        let endIndex = node.numberOfChildren
        while index < endIndex {
            let firstChild = node.children(index)
            if let paramKindValue = firstChild.functionSigSpecializationParamKind {
                if let kind = paramKindValue.kind {
                    switch kind {
                    case .BoxToValue,
                            .BoxToStack,
                            .InOutToOut:
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                    case .ConstantPropFunction,
                            .ConstantPropGlobal:
                        printer("[")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer(" : ")
                        let text = node.children(index).text
                        index += 1
                        let demangleName = try text.demangleSymbolAsString(
                            with: .defaultOptions,
                            printDebugInformation: false
                        )
                        printer(demangleName.emptyToNil() ?? text)
                        printer("]")
                    case .ConstantPropInteger,
                            .ConstantPropFloat:
                        printer("[")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer(" : ")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer("]")
                    case .ConstantPropString:
                        printer("[")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer(" : ")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer("'")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer("'")
                        printer("]")
                    case .ConstantPropKeyPath:
                        printer("[")
                        try printNode(node.getChild(index), depth: depth + 1)
                        index += 1
                        printer(" : ")
                        try printNode(node.getChild(index), depth: depth + 1)
                        index += 1
                        printer("<")
                        try printNode(node.getChild(index), depth: depth + 1)
                        index += 1
                        printer(",")
                        try printNode(node.getChild(index), depth: depth + 1)
                        index += 1
                        printer(">]")
                    case .ClosureProp:
                        printer("[")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer(" : ")
                        try printNode(node.children(index), depth: depth + 1)
                        index += 1
                        printer(", Argument Types : [")
                        while index < node.numberOfChildren {
                            let child = node.children(index)
                            // Until we no longer have a type node, keep demangling.
                            if child.kind != .Type {
                                break
                            }
                            try printNode(child, depth: depth + 1)
                            index += 1
                            
                            // If we are not done, print the ", ".
                            if index < node.numberOfChildren, node.children(index).text.emptyToNil() != nil {
                                printer(", ")
                            }
                        }
                        printer("]")
                    }
                } else {
                    assert(paramKindValue.isValidOptionSet, "Invalid OptionSet")
                    try printNode(node.children(index), depth: depth + 1)
                    index += 1
                }
            }
        }
    }
    
    func needSpaceBeforeType(type: Node) -> Bool {
        switch type.kind {
        case .Type:
            return needSpaceBeforeType(type: type.children(0))
        case .FunctionType,
                .NoEscapeFunctionType,
                .UncurriedFunctionType,
                .DependentGenericType:
            return false
        default:
            return true
        }
    }
    
    mutating func printBoundGenericNoSugar(node: Node, depth: Int) throws {
        guard node.numberOfChildren > 1 else {
            return
        }
        let typelist = node.children(1)
        try printNode(node.children(0), depth: depth + 1)
        printer("<")
        try printChildren(typelist, depth: depth, separator: ", ")
        printer(">")
    }
    
    mutating func printBoundGeneric(node: Node, depth: Int) throws {
        guard node.numberOfChildren > 1 else {
            return
        }
        guard node.numberOfChildren == 2 else {
            try printBoundGenericNoSugar(node: node, depth: depth)
            return
        }
        
        if !options.contains(.synthesizeSugarOnTypes) || node.kind == .BoundGenericClass {
            // no sugar here
            try printBoundGenericNoSugar(node: node, depth: depth)
            return
        }
        
        // Print the conforming type for a "bound" protocol node "as" the protocol
        // type.
        guard node.kind != .BoundGenericProtocol else {
            try printChildren(node.children(1), depth: depth)
            printer(" as ")
            try printNode(node.children(0), depth: depth + 1)
            return
        }
        
        let sugarType = findSugar(node)
        
        switch sugarType {
        case .none:
            try printBoundGenericNoSugar(node: node, depth: depth)
        case .optional,
                .implicitlyUnwrappedOptional:
            let type = node.children(1).children(0)
            try printWithParens(type, depth: depth)
            printer(sugarType == .optional ? "?" : "!")
        case .array:
            let type = node.children(1).children(0)
            printer("[")
            try printNode(type, depth: depth + 1)
            printer("]")
        case .dictionary:
            let keyType = node.children(1).children(0)
            let valueType = node.children(1).children(1)
            printer("[")
            try printNode(keyType, depth: depth + 1)
            printer(" : ")
            try printNode(valueType, depth: depth + 1)
            printer("]")
            break
        }
    }
    
    mutating func printWithParens(_ type: Node, depth: Int) throws {
        let needsParens = !type.isSimpleType
        if needsParens {
            printer("(")
        }
        try printNode(type, depth: depth + 1)
        if needsParens {
            printer(")")
        }
    }
    
    mutating func printAbstractStorage(node: Node, depth: Int, asPrefixContext: Bool, extraName: String) throws -> Node? {
        switch node.kind {
        case .Variable:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .withColon,
                hasName: true,
                extraName: extraName
            )
        case .Subscript:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .withColon,
                hasName: true,
                extraName: extraName,
                extraIndex: -1,
                overwriteName: "subscript"
            )
        default:
            throw SwiftDemangleError.nodePrinterError(description: "Not an abstract storage node", nodeDebugDescription: node.debugDescription)
        }
    }
    
    mutating func printImplFunctionType(function: Node, depth: Int) throws {
        var patternSubs: Node?
        var invocationSubs: Node?
        var sendingResult: Node?
        enum State: Int, CaseIterable, Equatable {
            case attrs, inputs, results
            
            var next: State? {
                State(rawValue: self.rawValue + 1)
            }
        }
        var currentState: State = .attrs
        func transitionTo(newState: State) throws {
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
                        try printNode(patternSubs.firstChild, depth: depth + 1)
                        printer(" ")
                    }
                    printer("(")
                    continue
                case .inputs:
                    printer(") -> ")
                    if let sendingResult {
                        try printNode(sendingResult, depth: depth + 1)
                        printer(" ")
                    }
                    printer("(")
                    continue
                case .results:
                    throw SwiftDemangleError.nodePrinterError(description: "no state after Results", nodeDebugDescription: String(describing: newState))
                }
            }
        }
        for child in function.copyOfChildren {
            switch child.kind {
            case .ImplParameter:
                if currentState == .inputs {
                    printer(", ")
                }
                try transitionTo(newState: .inputs)
                try printNode(child, depth: depth + 1)
            case .ImplResult,
                    .ImplYield,
                    .ImplErrorResult:
                if currentState == .results {
                    printer(", ")
                }
                try transitionTo(newState: .results)
                try printNode(child, depth: depth + 1)
            case .ImplPatternSubstitutions:
                patternSubs = child
            case .ImplInvocationSubstitutions:
                invocationSubs = child
            case .ImplSendingResult:
                sendingResult = child
            default:
                assert(currentState == .attrs)
                try printNode(child, depth: depth + 1)
                printer(" ")
            }
        }
        try transitionTo(newState: .results)
        printer(")")
        
        if let subs = patternSubs {
            printer(" for <")
            try printChildren(subs.children(1), depth: depth)
            printer(">")
        }
        if let subs = invocationSubs {
            printer(" for <")
            try printChildren(subs.children(0), depth: depth)
            printer(">")
        }
    }
    
    mutating func printGenericSignature(node: Node, depth: Int) {
        printer(">")
        
        let numChildren = node.numberOfChildren
        
        let numGenericParams = node.copyOfChildren.prefix { $0.kind == .DependentGenericParamCount }.count
        
        var firstRequirement = numGenericParams
        while firstRequirement < numChildren {
            var child = node.children(firstRequirement)
            if child.kind == .Type {
                child = child.children(0)
            }
            if child.kind != .DependentGenericParamPackMarker &&
                child.kind != .DependentGenericParamValueMarker {
                break
            }
            firstRequirement += 1
        }
        
        func isGenericParamPack(depth: UInt64, index: UInt64, numGenericParams: Int, firstRequirement: Int) -> Bool {
            for i in numGenericParams..<firstRequirement {
                var child = node.children(i)
                if child.kind != .DependentGenericParamPackMarker {
                    continue
                }
                child = child.children(0)
                
                if child.kind != .Type {
                    continue
                }
                
                child = child.children(0)
                if child.kind != .DependentGenericParamType {
                    continue
                }
                
                if index == child.children(0).index &&
                    depth == child.children(1).index {
                    return true
                }
            }
            
            return false
        }
        
        func isGenericParamValue(depth: UInt64, index: UInt64, numGenericParams: Int, firstRequirement: Int) -> (Bool, Node?) {
            for i in numGenericParams..<firstRequirement {
                var child = node.children(i)
                if child.kind != .DependentGenericParamValueMarker {
                    continue
                }
                child = child.children(0)
                
                if child.kind != .Type {
                    continue
                }
                
                let param = child.children(0)
                let type = child.children(1)
                if param.kind != .DependentGenericParamType {
                    continue
                }
                
                if index == param.children(0).index &&
                    depth == param.children(1).index {
                    return (true, type)
                }
            }
            
            return (false, nil)
        }
        
        for gpDepth in 0..<numGenericParams {
            if gpDepth != 0 {
                printer("><")
            }
            if let count = node.children(gpDepth).index {
                for index in 0..<count {
                    if index != 0 {
                        printer(", ")
                    }
                    
                    if (index >= 128) {
                        printer("...")
                        break
                    }
                    
                    if isGenericParamPack(depth: UInt64(gpDepth), index: index, numGenericParams: numGenericParams, firstRequirement: firstRequirement) {
                        printer("each ")
                    }
                    let (isValue, value) = isGenericParamValue(depth: UInt64(gpDepth), index: index, numGenericParams: numGenericParams, firstRequirement: firstRequirement)
                    
                    if isValue {
                        printer("let ")
                    }
                    printer(options.genericParameterName(depth: UInt64(gpDepth), index: index))
                    
                    if let node = value {
                        printer(": ")
                        print(node, depth + 1)
                    }
                }
            }
        }
        
        if firstRequirement != numChildren {
            if options.contains(.displayWhereClauses) {
                printer(" where ")
                for i in firstRequirement..<numChildren {
                    if i > firstRequirement {
                        printer(", ")
                    }
                    print(node.children(i), depth + 1)
                }
            }
        }
        printer(">")
    }
    
    func findSugar(_ node: Node) -> SugarType {
        if node.numberOfChildren == 1, node.kind == .Type {
            return findSugar(node.children(0))
        }
        
        if node.numberOfChildren != 2 {
            return .none
        }
        
        if node.kind != .BoundGenericEnum, node.kind != .BoundGenericStructure {
            return .none
        }
        
        let unboundType = node.children(0).children(0) // drill through Type
        let typeArgs = node.children(1)
        
        if node.kind == .BoundGenericEnum {
            // Swift.Optional
            if unboundType.children(1).isIdentifier(desired: "Optional"),
               typeArgs.numberOfChildren == 1,
               unboundType.children(0).isSwiftModule {
                return .optional
            }
            
            // Swift.ImplicitlyUnwrappedOptional
            if unboundType.children(1).isIdentifier(desired: "ImplicitlyUnwrappedOptional"),
               typeArgs.numberOfChildren == 1,
               unboundType.children(0).isSwiftModule {
                return .implicitlyUnwrappedOptional
            }
            
            return .none
        }
        
        assert(node.kind == .BoundGenericStructure)
        
        // Array
        if unboundType.children(1).isIdentifier(desired: "Array"),
           typeArgs.numberOfChildren == 1,
           unboundType.children(0).isSwiftModule {
            return .array
        }
        
        // Dictionary
        if unboundType.children(1).isIdentifier(desired: "Dictionary"),
           typeArgs.numberOfChildren == 2,
           unboundType.children(0).isSwiftModule {
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
    
    func nodeToString(root: Node?) -> String {
        guard let root else {
            return ""
        }
        var printer = NodePrinter(options: self.options)
        do {
            return try printer.printRoot(root)
        } catch {
            debugPrint("[SwiftDemangle] nodeToString failed by \(error)")
            return ""
        }
    }
}
