//
//  OldDemangler+ImplFunctionTypes.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    // impl-function-type ::= impl-callee-convention impl-function-attribute*
    //                        generics? '_' impl-parameter* '_' impl-result* '_'
    // impl-function-attribute ::= 'Cb'            // compatible with C block invocation function
    // impl-function-attribute ::= 'Cc'            // compatible with C global function
    // impl-function-attribute ::= 'Cm'            // compatible with Swift method
    // impl-function-attribute ::= 'CO'            // compatible with ObjC method
    // impl-function-attribute ::= 'Cw'            // compatible with protocol witness
    // impl-function-attribute ::= 'G'             // generic
    func demangleImplFunctionType() -> Node? {
        var type = Node(kind: .ImplFunctionType)
        
        guard demangleImplCalleeConvention(type: &type) else { return nil }
        
        if nextIf("C") {
            if nextIf("b") {
                addImplFunctionConvention(parent: &type, attr: "block")
            } else if nextIf("c") {
                addImplFunctionConvention(parent: &type, attr: "c")
            } else if nextIf("m") {
                addImplFunctionConvention(parent: &type, attr: "method")
            } else if nextIf("O") {
                addImplFunctionConvention(parent: &type, attr: "objc_method")
            } else if nextIf("w") {
                addImplFunctionConvention(parent: &type, attr: "witness_method")
            } else {
                return nil
            }
        }
        
        if nextIf("h") {
            addImplFunctionAttribute(parent: &type, attr: "@Sendable")
        }
        
        if nextIf("H") {
            addImplFunctionAttribute(parent: &type, attr: "@async")
        }
        
        // Enter a new generic context if this type is generic.
        // FIXME: replace with std::optional, when we have it.
        var isPseudogeneric = false
        if nextIf("G") || nextIf("g").bind(to: &isPseudogeneric) {
            guard let generics = demangleGenericSignature(isPseudogeneric: isPseudogeneric) else { return nil }
            type.add(generics)
        }
        
        // Expect the attribute terminator.
        guard nextIf("_") else { return nil }
        
        // Demangle the parameters.
        guard demangleImplParameters(parent: &type) else { return nil }
        
        // Demangle the result type.
        guard demangleImplResults(parent: &type) else { return nil }
        
        return type
    }
    
    enum ImplConventionContext {
        case Callee, Parameter, Result
        
        func to(callee: String = "", parameter: String = "", result: String = "") -> String {
            switch self {
            case .Callee:
                return callee
            case .Parameter:
                return parameter
            case .Result:
                return result
            }
        }
    }

    /// impl-convention ::= 'a'                     // direct, autoreleased
    /// impl-convention ::= 'd'                     // direct, no ownership transfer
    /// impl-convention ::= 'D'                     // direct, no ownership transfer,
    ///                                             // dependent on self
    /// impl-convention ::= 'g'                     // direct, guaranteed
    /// impl-convention ::= 'e'                     // direct, deallocating
    /// impl-convention ::= 'i'                     // indirect, ownership transfer
    /// impl-convention ::= 'l'                     // indirect, inout
    /// impl-convention ::= 'o'                     // direct, ownership transfer
    ///
    /// Returns an empty string otherwise.
    func demangleImplConvention(ctx: ImplConventionContext) -> String {
        if nextIf("a") {
            return ctx.to(result: "@autoreleased")
        }
        if nextIf("d") {
            return ctx.to(callee: "@callee_unowned", parameter: "@unowned", result: "@unowned")
        }
        if nextIf("D") {
            return ctx.to(result: "@unowned_inner_pointer")
        }
        if nextIf("g") {
            return ctx.to(callee: "@callee_guaranteed", parameter: "@guaranteed")
        }
        if nextIf("e") {
            return ctx.to(parameter: "@deallocating")
        }
        if nextIf("i") {
            return ctx.to(parameter: "@in", result: "@out")
        }
        if nextIf("l") {
            return ctx.to(parameter: "@inout")
        }
        if nextIf("o") {
            return ctx.to(callee: "@callee_owned", parameter: "@owned", result: "@owned")
        }
        return ""
    }

    // impl-callee-convention ::= 't'
    // impl-callee-convention ::= impl-convention
    func demangleImplCalleeConvention(type: inout Node) -> Bool {
        var attr = ""
        if nextIf("t") {
            attr = "@convention(thin)"
        } else {
            attr = demangleImplConvention(ctx: .Callee)
        }
        if attr.isEmpty {
            return false
        } else {
            type.add(Node(kind: .ImplConvention, text: attr))
            return true
        }
    }
    
    func addImplFunctionAttribute(parent: inout Node, attr: String, kind: Node.Kind = .ImplFunctionAttribute) {
        parent.add(kind: kind, text: attr)
    }

    func addImplFunctionConvention(parent: inout Node, attr: String) {
        let attrNode = Node(kind: .ImplFunctionConvention)
        attrNode.add(.init(kind: .ImplFunctionConventionName, text: attr))
        parent.add(attrNode)
    }

    // impl-parameter ::= impl-convention type
    func demangleImplParameters(parent: inout Node) -> Bool {
        while !nextIf("_") {
            guard let input = demangleImplParameterOrResult(kind: .ImplParameter) else { return false }
            parent.add(input)
        }
        return true
    }

    // impl-result ::= impl-convention type
    func demangleImplResults(parent: inout Node) -> Bool {
        while !nextIf("_") {
            guard let res = demangleImplParameterOrResult(kind: .ImplResult) else { return false }
            parent.add(res)
        }
        return true
    }
    
    func demangleImplParameterOrResult(kind: Node.Kind) -> Node? {
        var kind = kind
        if nextIf("z") {
            // Only valid for a result.
            guard kind == .ImplResult else { return nil }
            kind = .ImplErrorResult
        }
        
        let convCtx: ImplConventionContext
        if kind == .ImplParameter {
            convCtx = .Parameter
        } else if kind == .ImplResult || kind == .ImplErrorResult {
            convCtx = .Result
        } else {
            return nil
        }
        
        guard let convention = demangleImplConvention(ctx: convCtx).emptyToNil() else { return nil }
        guard let type = demangleType() else { return nil }
        
        let node = Node(kind: kind)
        node.add(kind: .ImplConvention, text: convention)
        node.add(type)
        
        return node
    }
}
