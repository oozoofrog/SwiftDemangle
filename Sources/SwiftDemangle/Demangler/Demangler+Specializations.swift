//
//  Demangler+Specializations.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleBridgedMethodParams() -> String {
        if nextIf("_") {
            return ""
        }
        
        var Str = ""
        
        let kind = nextChar()
        switch kind {
        case "p", "a", "m":
            Str.append(kind)
        default:
            return ""
        }
        
        while !nextIf("_") {
            let c = nextChar()
            if c != "n" && c != "b" && c != "g" {
                return ""
            }
            Str.append(c)
        }
        return Str
    }
    
    func demangleGenericSpecialization(_ SpecKind: Node.Kind, _ droppedArguments: Node? = nil) -> Node? {
        guard let Spec = demangleSpecAttributes(SpecKind) else { return nil }
        if let droppedArguments = droppedArguments?.copyOfChildren {
            for droppedArguments in droppedArguments {
                Spec.addChild(droppedArguments)
            }
        }
        guard let TyList = popTypeList() else { return nil }
        for Ty in TyList.copyOfChildren {
            Spec.addChild(createWithChild(.GenericSpecializationParam, Ty))
        }
        return Spec
    }
    
    func demangleGenericSpecializationWithDroppedArguments() -> Node? {
        pushBack()
        let tmp = createNode(.GenericSpecialization)
        while nextIf("t") {
            let n = demangleNatural()
            addChild(tmp, createNode(.DroppedArgument, n < 0 ? 0 : n + 1))
        }
        let specKind: Node.Kind
        switch nextChar() {
        case "g":
            specKind = .GenericSpecialization
        case "G":
            specKind = .GenericSpecializationNotReAbstracted
        case "B":
            specKind = .GenericSpecializationInResilienceDomain
        default:
            return nil
        }
        return demangleGenericSpecialization(specKind, tmp)
    }

    func demangleFunctionSpecialization() -> Node? {
        var Spec = demangleSpecAttributes(.FunctionSignatureSpecialization)
        if let Spec, Spec.copyOfChildren.first?.getKind() == .RepresentationChanged {
            return Spec
        }
        while Spec.hasValue, !nextIf("_") {
            Spec = addChild(Spec, demangleFuncSpecParam(.FunctionSignatureSpecializationParam))
        }
        if !nextIf("n") {
            Spec = addChild(Spec, demangleFuncSpecParam(.FunctionSignatureSpecializationReturn))
        }
        
        if !Spec {
            return nil
        }
        
        // Add the required parameters in reverse order.
        for Param in Spec?.copyOfChildren.reversed() ?? [] {
            if Param.getKind() != .FunctionSignatureSpecializationParam {
                continue
            }
            
            let fixedChildren = Param.getNumChildren()
            var paramToAdd: Node? = Param
            for childIdx in 0..<fixedChildren {
                let KindNd = Param.getChild(fixedChildren - childIdx - 1)
                if KindNd.getKind() != .FunctionSignatureSpecializationParamKind {
                    continue
                }
                
                switch KindNd.functionSigSpecializationParamKind?.kind {
                case .ClosureProp, .EscapingClosureProp:
                    while let Ty = popNode(.Type) {
                        paramToAdd = addChild(paramToAdd, Ty)
                    }
                case .ConstantPropKeyPath:
                    paramToAdd = addChild(paramToAdd, popNode(.Type))
                    paramToAdd = addChild(paramToAdd, popNode(.Type))
                case .ConstantPropStruct:
                    paramToAdd = addChild(paramToAdd, popNode(.Type))
                    continue
                case .ConstantPropFunction, .ConstantPropGlobal, .ConstantPropString:
                    break
                default:
                    continue
                }
                paramToAdd = addChild(paramToAdd, popNode(.Identifier))
            }
            if paramToAdd == nil {
                return nil
            }
            Param.reverseChildren(fixedChildren)
        }
        // The parameters grew after they were attached.
        Spec?.recomputeHeight()
        return Spec
    }
    
    func demangleFuncSpecParam(_ Kind: Node.Kind) -> Node? {
        assert(Kind == .FunctionSignatureSpecializationParam || Kind == .FunctionSignatureSpecializationReturn)
        let Param = createNode(Kind)
        switch nextChar() {
        case "n":
            return Param
        case "c":
            // Consumes an identifier and multiple type parameters.
            // The parameters will be added later.
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ClosureProp))
        case "E":
            // Like "c", but for escaping closures. Consumes an identifier and
            // multiple type parameters. The parameters will be added later.
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .EscapingClosureProp))
        case "C":
            // Refers to the closure of a previous argument.
            addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ClosurePropPreviousArg))
            let prevArgIdx = demangleNatural()
            if prevArgIdx < 0 {
                return nil
            }
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamPayload, UInt64(prevArgIdx)))
        case "p":
            // Constant propagation operators can follow each other, e.g. "pSSi3Si0".
            while true {
                switch nextChar() {
                case "S":
                    // Consumes a type parameter, which will be added later.
                    addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ConstantPropStruct))
                case "f":
                    // Consumes an identifier parameter, which will be added later.
                    addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ConstantPropFunction))
                case "g":
                    // Consumes an identifier parameter, which will be added later.
                    addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ConstantPropGlobal))
                case "i":
                    if addFuncSpecParamNumber(Param, .ConstantPropInteger) == nil {
                        return nil
                    }
                case "d":
                    if addFuncSpecParamNumber(Param, .ConstantPropFloat) == nil {
                        return nil
                    }
                case "s":
                    // Consumes an identifier parameter (the string constant),
                    // which will be added later.
                    let Encoding: String
                    switch nextChar() {
                    case "b":
                        Encoding = "u8"
                    case "w":
                        Encoding = "u16"
                    case "c":
                        Encoding = "objc"
                    default:
                        return nil
                    }
                    addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ConstantPropString))
                    addChild(Param, createNode(.FunctionSignatureSpecializationParamPayload, Encoding))
                case "k":
                    // Consumes two types and a SHA1 identifier.
                    addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .ConstantPropKeyPath))
                case .zero:
                    // End of input. Pushing back here would re-read the last
                    // character forever, which upstream does.
                    return nil
                default:
                    pushBack()
                    return Param
                }
            }
            
        case "e":
            var Value = FunctionSigSpecializationParamKind.OptionSet.ExistentialToGeneric
            if nextIf("D") {
                Value.insert(.Dead)
            }
            if nextIf("G") {
                Value.insert(.OwnedToGuaranteed)
            }
            if nextIf("O") {
                Value.insert(.GuaranteedToOwned)
            }
            if nextIf("X") {
                Value.insert(.SROA)
            }
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, Value))
        case "d":
            var Value = FunctionSigSpecializationParamKind.OptionSet.Dead
            if nextIf("G") {
                Value.insert(.OwnedToGuaranteed)
            }
            if nextIf("O") {
                Value.insert(.GuaranteedToOwned)
            }
            if nextIf("X") {
                Value.insert(.SROA)
            }
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, Value))
        case "g":
            var Value = FunctionSigSpecializationParamKind.OptionSet.OwnedToGuaranteed
            if nextIf("X") {
                Value.insert(.SROA)
            }
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, Value))
        case "o":
            var Value = FunctionSigSpecializationParamKind.OptionSet.GuaranteedToOwned
            if nextIf("X") {
                Value.insert(.SROA)
            }
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, Value))
        case "x":
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .SROA))
        case "i":
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .BoxToValue))
        case "s":
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .BoxToStack))
        case "r":
            return addChild(Param, createNode(.FunctionSignatureSpecializationParamKind, .InOutToOut))
        default:
            return nil
        }
    }
    
    func demangleSpecAttributes(_ SpecKind: Node.Kind) -> Node? {
        let isSerialized = nextIf("q")
        let asyncRemoved = nextIf("a")
        let representationChanged = nextIf("r")
        
        let PassID = nextChar() - "0"
        guard (0...9).contains(PassID) else { return nil }
        
        let SpecNd = createNode(SpecKind)
        
        if isSerialized {
            SpecNd.addChild(createNode(.IsSerialized))
        }
        
        if asyncRemoved {
            SpecNd.addChild(createNode(.AsyncRemoved))
        }
        
        if representationChanged {
            SpecNd.addChild(createNode(.RepresentationChanged))
        }
        
        SpecNd.addChild(createNode(.SpecializationPassID, PassID))
        return SpecNd
    }
}
