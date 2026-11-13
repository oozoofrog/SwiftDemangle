//
//  Demangler+ImplFunctionType.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleImplParamConvention(_ ConvKind: Node.Kind) -> Node? {
        let attr: String
        switch nextChar() {
        case "i": 
            attr = "@in"
        case "c":
            attr = "@in_constant"
        case "l":
            attr = "@inout"
        case "b":
            attr = "@inout_aliasable"
        case "n":
            attr = "@in_guaranteed"
        case "X":
            attr = "@in_cxx"
        case "x":
            attr = "@owned"
        case "g":
            attr = "@guaranteed"
        case "e":
            attr = "@deallocating"
        case "y":
            attr = "@unowned"
        case "v":
            attr = "@pack_owned"
        case "p":
            attr = "@pack_guaranteed"
        case "m":
            attr = "@pack_inout"
        default:
            pushBack()
            return nil
        }
        return createWithChild(ConvKind, createNode(.ImplConvention, attr))
    }
    
    func demangleImplResultConvention(_ ConvKind: Node.Kind) -> Node? {
        let attr: String
        switch nextChar() {
        case "r": attr = "@out"
        case "o": attr = "@owned"
        case "d": attr = "@unowned"
        case "u": attr = "@unowned_inner_pointer"
        case "a": attr = "@autoreleased"
        case "k": attr = "@pack_out"
        case "l": attr = "@guaranteed_address"
        case "g": attr = "@guaranteed"
        case "m": attr = "@inout"
        default:
            pushBack()
            return nil
        }
        return createWithChild(ConvKind, createNode(.ImplConvention, attr))
    }

    func demangleImplParameterSending() -> Node? {
        // Empty string represents default differentiability.
        if !nextIf("T") {
            return nil
        }
        return createNode(.ImplParameterSending, "sending")
    }

    func demangleImplParameterIsolated() -> Node? {
        if !nextIf("I") { return nil }
        return createNode(.ImplParameterIsolated, "isolated")
    }

    func demangleImplParameterImplicitLeading() -> Node? {
        if !nextIf("L") { return nil }
        return createNode(.ImplParameterImplicitLeading, "sil_implicit_leading_param")
    }
    
    func demangleImplParameterResultDifferentiability() -> Node? {
        // Empty string represents default differentiability.
        let attr: String
        if nextIf("w") {
            attr = "@noDerivative"
        } else {
            attr = ""
        }
        return createNode(.ImplParameterResultDifferentiability, attr)
    }
    
    func demangleClangType() -> Node? {
        let numChars = demangleNatural()
        guard numChars > 0 else { return nil }
        var mangledClangType: String = ""
        mangledClangType.append(nextString(numChars))
        return createNode(.ClangType, mangledClangType)
    }
    
    func demangleImplFunctionType() -> Node? {
        var type: Node? = createNode(.ImplFunctionType)
        
        if nextIf("s") {
            var Substitutions: [Node] = []
            var SubstitutionRetroConformances: Node?
            if !demangleBoundGenerics(&Substitutions, &SubstitutionRetroConformances) { return nil }
            
            let sig = popNode(.DependentGenericSignature)
            if !sig { return nil }
            
            let subsNode = createNode(.ImplPatternSubstitutions)
            subsNode.addChild(sig)
            // Demangler.cpp asserts a single list and uses the first one.
            guard let substitution = Substitutions.first else { return nil }
            subsNode.addChild(substitution)
            if SubstitutionRetroConformances.hasValue {
                subsNode.addChild(SubstitutionRetroConformances)
            }
            type.addChild(subsNode)
        }

        if nextIf("I") {
            var Substitutions: [Node] = []
            var SubstitutionRetroConformances: Node?
            if !demangleBoundGenerics(&Substitutions, &SubstitutionRetroConformances) { return nil }

            let subsNode = createNode(.ImplInvocationSubstitutions)
            if Substitutions.size() != 1 { return nil }
            subsNode.addChild(Substitutions[0])
            if SubstitutionRetroConformances.hasValue {
                subsNode.addChild(SubstitutionRetroConformances)
            }
            type.addChild(subsNode)
        }
        
        var GenSig = popNode(.DependentGenericSignature)
        if GenSig.hasValue && nextIf("P") {
            GenSig = changeKind(GenSig, .DependentPseudogenericSignature)
        }
        
        if nextIf("e") { type.addChild(createNode(.ImplEscaping)) }
        
        if nextIf("A") {
            type.addChild(createNode(.ImplErasedIsolation))
        }
        
        if nextIf("N") {
            type.addChild(createNode(.ImplNonisolatedNonsendingIsolation))
        }
        
        switch MangledDifferentiabilityKind(rawValue: peekChar().description) {
        case .normal,  // "d"
                .linear,  // "l"
                .forward, // "f"
                .reverse: // "r"
            type.addChild(createNode(.ImplDifferentiabilityKind, nextChar()))
        default:
            break
        }
        
        let CAttr: String
        switch nextChar() {
        case "y": CAttr = "@callee_unowned"
        case "g": CAttr = "@callee_guaranteed"
        case "x": CAttr = "@callee_owned"
        case "t": CAttr = "@convention(thin)"
        default: return nil
        }
        type.addChild(createNode(.ImplConvention, CAttr))
        
        var FConv: String = ""
        var hasClangType = false
        switch nextChar() {
        case "B": FConv = "block"
        case "C": FConv = "c"
        case "z":
            switch nextChar() {
            case "B":
                hasClangType = true
                FConv = "block"
            case "C":
                hasClangType = true
                FConv = "c"
            default:
                pushBack()
                pushBack()
            }
        case "M": FConv = "method"
        case "O": FConv = "objc_method"
        case "K": FConv = "closure"
        case "W": FConv = "witness_method"
        default: pushBack()
        }
        if FConv.isNotEmpty {
            let FAttrNode = createNode(.ImplFunctionConvention)
            FAttrNode.addChild(createNode(.ImplFunctionConventionName, FConv))
            if hasClangType {
                FAttrNode.addChild(demangleClangType())
            }
            type.addChild(FAttrNode)
        }
        
        var CoroAttr: String?
        if nextIf("A") {
            CoroAttr = "yield_once"
        } else if nextIf("I") {
            CoroAttr = "yield_once_2"
        } else if nextIf("G") {
            CoroAttr = "yield_many"
        }
        if let CoroAttr {
            type.addChild(createNode(.ImplCoroutineKind, CoroAttr))
        }
        
        if nextIf("h") {
            type.addChild(createNode(.ImplFunctionAttribute, "@Sendable"))
        }
        
        if nextIf("H") {
            type.addChild(createNode(.ImplFunctionAttribute, "@async"))
        }

        if nextIf("T") {
            type.addChild(createNode(.ImplSendingResult))
        }

        addChild(type, GenSig)

        var NumTypesToAdd = 0
        var Param: Node?
        while let param = demangleImplParamConvention(.ImplParameter) {
            Param = param
            type = addChild(type, Param)
            if let Diff = demangleImplParameterResultDifferentiability() {
                Param = addChild(Param, Diff)
            }
            if let Sending = demangleImplParameterSending() {
                Param = addChild(Param, Sending)
            }
            if let Isolated = demangleImplParameterIsolated() {
                Param = addChild(Param, Isolated)
            }
            if let ImplicitLeading = demangleImplParameterImplicitLeading() {
                Param = addChild(Param, ImplicitLeading)
            }
            NumTypesToAdd += 1
        }

        var Result: Node?
        while let result = demangleImplResultConvention(.ImplResult) {
            type = addChild(type, result)
            if let Diff = demangleImplParameterResultDifferentiability() {
                Result = addChild(result, Diff)
            }
            ++NumTypesToAdd
            if Result == nil {
                break
            }
        }
        while nextIf("Y") {
            let YieldResult =
            demangleImplParamConvention(.ImplYield)
            if !YieldResult { return nil }
            type = addChild(type, YieldResult)
            ++NumTypesToAdd
        }
        if nextIf("z") {
            let ErrorResult = demangleImplResultConvention(
                .ImplErrorResult)
            if !ErrorResult { return nil }
            type = addChild(type, ErrorResult)
            ++NumTypesToAdd
        }
        if !nextIf("_") { return nil }
        
        for Idx in 0..<NumTypesToAdd {
            let ConvTy = popNode(.Type)
            if !ConvTy { return nil }
            type.getChild(type.getNumChildren() - Idx - 1).addChild(ConvTy)
        }
        // The parameters and results grew after they were attached.
        type?.recomputeHeight()
        
        return createType(type)
    }
}
