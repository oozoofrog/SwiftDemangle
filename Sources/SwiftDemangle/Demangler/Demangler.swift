//
//  Demangler.swift
//  Demangling
//
//  Created by spacefrog on 2021/06/06.
//

import Foundation

class Demangler: Demanglerable, Mangling {
    let buffer: [UInt8]
    var position: Int = 0
    let numerics: [Character] = (0...9).map(\.description).map(Character.init)
    
    var substitutions: [Node] = []
    
    var nodeStack: [Node] = []
    let maxNumWords = 26
    var words: [String] = []
    var numWords: Int { words.count }
    
    var IsOldFunctionTypeMangling: Bool = false
    
    required init(_ mangled: String) {
        self.buffer = Self.bytes(of: mangled)
    }
    
    func demangleOldSymbolAsNode(_ mangled: String) -> Node? {
        OldDemangler(mangled).demangleTopLevel()
    }
    
    func demangleSymbol() -> Node? {
        // Demangle old-style class and protocol names, which are still used in the
        // ObjC metadata.
        if nextIf("_Tt") {
            return demangleOldSymbolAsNode(self.text)
        }
        
        let PrefixLength = self.manglingPrefixLength(from: self.textOriginal)
        if PrefixLength == 0 {
            return nil
        }
        
        self.IsOldFunctionTypeMangling = self.isOldFunctionType(self.textOriginal)
        advanceOffset(PrefixLength)
        
        // If any other prefixes are accepted, please update Mangler::verify.
        
        if !parseAndPushNodes() {
            return nil
        }
        
        let topLevel = createNode(.Global)
        let suffix = popNode(.Suffix)
        var Parent = topLevel
        // Partial apply forwarders nest everything after them, so track how deep Parent is.
        var parentDepth = 0
        var parents = [topLevel]
        while let FuncAttr = popNode(isFunctionAttr) {
            guard parentDepth + 1 + FuncAttr.height <= Node.maxDepth else { return nil }
            Parent.addChild(FuncAttr)
            if FuncAttr.getKind() == .PartialApplyForwarder || FuncAttr.getKind() == .PartialApplyObjCForwarder {
                Parent = FuncAttr
                parentDepth += 1
                parents.append(FuncAttr)
            }
        }
        for Nd in nodeStack {
            let child = Nd.getKind() == .Type ? Nd.getFirstChild() : Nd
            guard parentDepth + 1 + child.height <= Node.maxDepth else { return nil }
            Parent.addChild(child)
        }
        
        // A forwarder gained its children after it was attached.
        for parent in parents.reversed() {
            parent.recomputeHeight()
        }
        
        if let suffix {
            topLevel.addChild(suffix)
        }
        
        if topLevel.getNumChildren() == 0 {
            return nil
        }
        
        return topLevel
    }
    
    @discardableResult
    func parseAndPushNodes() -> Bool {
        while isNotEmpty {
            guard let node = demangleOperator(), node.height <= Node.maxDepth else { return false }
            pushNode(node)
        }
        return true
    }
    
    func demangleTypeMangling() -> Node? {
        let type = popNode(.Type)
        let LabelList = popFunctionParamLabels(type)
        var TypeMangling: Node? = createNode(.TypeMangling)
        
        addChild(TypeMangling, LabelList)
        TypeMangling = addChild(TypeMangling, type)
        return TypeMangling
    }
    
    func demangleTypeAnnotation() -> Node? {
        switch nextChar() {
        case "a":
            return createNode(.AsyncAnnotation)
        case "A":
            return createNode(.IsolatedAnyFunctionType)
        case "b":
            return createNode(.ConcurrentFunctionType)
        case "c":
            return createWithChild(.GlobalActorFunctionType, popTypeAndGetChild())
        case "i":
            return createType(createWithChild(.Isolated, popTypeAndGetChild()))
        case "j":
            return demangleDifferentiableFunctionType()
        case "k":
            return createType(createWithChild(.NoDerivative, popTypeAndGetChild()))
        case "K":
            return createWithChild(.TypedThrowsAnnotation, popTypeAndGetChild())
        case "t":
            return createType(createWithChild(.CompileTimeLiteral, popTypeAndGetChild()))
        case "T":
            return createNode(.SendingResultFunctionType)
        case "u":
            return createType(createWithChild(.Sending, popTypeAndGetChild()))
        case "C":
            return createNode(.NonIsolatedCallerFunctionType)
        case "g":
            return createType(createWithChild(.ConstValue, popTypeAndGetChild()))
        default:
            return nil
        }
    }
    
    func demangleOperator() -> Node? {
        while true {
            let c = nextChar()
            switch c {
            case 0xFF:
                // A 0xFF byte is used as alignment padding for symbolic references
                // when the platform toolchain has alignment restrictions for the
                // relocations that form the reference value. It can be skipped.
                continue
            case 1, 2, 3, 4, 5, 6, 7, 8, 9, 0xA, 0xB, 0xC:
                // A symbolic reference points into the binary that holds the symbol.
                // Without a resolver for it, refuse to demangle further.
                return nil
            case "A": return demangleMultiSubstitutions()
            case "B": return demangleBuiltinType()
            case "C": return demangleAnyGenericType(.Class)
            case "D": return demangleTypeMangling()
            case "E": return demangleExtensionContext()
            case "F": return demanglePlainFunction()
            case "G": return demangleBoundGenericType()
            case "H":
                switch nextChar() {
                case "A": return demangleDependentProtocolConformanceAssociated()
                case "C": return demangleConcreteProtocolConformance()
                case "D": return demangleDependentProtocolConformanceRoot()
                case "I": return demangleDependentProtocolConformanceInherited()
                case "O": return demangleDependentProtocolConformanceOpaque()
                case "P":
                    return createWithChild(.ProtocolConformanceRefInTypeModule, popProtocol())
                case "p":
                    return createWithChild(.ProtocolConformanceRefInProtocolModule, popProtocol())
                case "X":
                    return demanglePackProtocolConformance()
                case "c":
                    return createWithChild(.ProtocolConformanceDescriptorRecord, popProtocolConformance())
                case "n":
                    return createWithPoppedType(.NominalTypeDescriptorRecord)
                case "o": // XXX
                    return createWithChild(.OpaqueTypeDescriptorRecord, popNode())
                case "r":
                    return createWithChild(.ProtocolDescriptorRecord, popProtocol())
                case "F":
                    return createNode(.AccessibleFunctionRecord)
                default:
                    pushBack()
                    pushBack()
                    return demangleIdentifier()
                }
            case "I": return demangleImplFunctionType()
            case "K": return createNode(.ThrowsAnnotation)
            case "L": return demangleLocalIdentifier()
            case "M": return demangleMetatype()
            case "N": return createWithChild(.TypeMetadata, popNode(.Type))
            case "O": return demangleAnyGenericType(.Enum)
            case "P": return demangleAnyGenericType(.Protocol)
            case "Q": return demangleArchetype()
            case "R": return demangleGenericRequirement()
            case "S": return demangleStandardSubstitution()
            case "T": return demangleThunkOrSpecialization()
            case "V": return demangleAnyGenericType(.Structure)
            case "W": return demangleWitness()
            case "X": return demangleSpecialType()
            case "Y": return demangleTypeAnnotation()
            case "Z": return createWithChild(.Static, popNode(isEntity))
            case "a": return demangleAnyGenericType(.TypeAlias)
            case "c": return popFunctionType(.FunctionType)
            case "d": return createNode(.VariadicMarker)
            case "f": return demangleFunctionEntity()
            case "g": return demangleRetroactiveConformance()
            case "h": return createType(createWithChild(.Shared, popTypeAndGetChild()))
            case "i": return demangleSubscript()
            case "l": return demangleGenericSignature(/*hasParamCounts*/ false)
            case "m": return createType(createWithChild(.Metatype, popNode(.Type)))
            case "n":
                return createType(createWithChild(.Owned, popTypeAndGetChild()))
            case "o": return demangleOperatorIdentifier()
            case "p": return demangleProtocolListType()
            case "q": return createType(demangleGenericParamIndex())
            case "r": return demangleGenericSignature(/*hasParamCounts*/ true)
            case "s": return createNode(.Module, .STDLIB_NAME)
            case "t": return popTuple()
            case "u": return demangleGenericType()
            case "v": return demangleVariable()
            case "w": return demangleValueWitness()
            case "x": return createType(getDependentGenericParamType(0, 0))
            case "y": return createNode(.EmptyList)
            case "z": return createType(createWithChild(.InOut, popTypeAndGetChild()))
            case "_": return createNode(.FirstElementMarker)
            case ".":
                // IRGen still uses '.<n>' to disambiguate partial apply thunks and
                // outlined copy functions. We treat such a suffix as "unmangled suffix".
                pushBack()
                return createNode(.Suffix, consumeAll())
            case "$":
                return demangleIntegerType()
            default:
                pushBack()
                return demangleIdentifier()
            }
        }
    }
}
