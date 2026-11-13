//
//  NodePrinter+Specialization.swift
//  Demangling
//

import Foundation

extension NodePrinter {
    
    mutating func printSpecializationPrefix(node: Node, description: String, depth: Int, paramPrefix: String? = nil) throws {
        if !options.contains(.displayGenericSpecializations) {
            if (!isSpecializationPrefixPrinted) {
                printer("specialized ")
                isSpecializationPrefixPrinted = true
            }
            return
        }
        if node.copyOfChildren.first?.kind == .RepresentationChanged {
            printer("representation changed of ")
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
        var argIndex = 0
        let endIndex = node.numberOfChildren
        while index < endIndex {
            let child = node.children(index)
            guard let paramKindValue = child.functionSigSpecializationParamKind else { return }
            guard let kind = paramKindValue.kind else {
                assert(paramKindValue.isValidOptionSet, "Invalid OptionSet")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                continue
            }
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
                try printNextParamChildNode(node: node, index: &argIndex, kind: kind, depth: depth)
                printer("]")
            case .ConstantPropInteger,
                    .ConstantPropFloat:
                if index + 2 > endIndex { return }
                printer("[")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer(" : ")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer("]")
            case .ConstantPropString:
                if index + 2 > endIndex { return }
                printer("[")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer(" : ")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer("'")
                try printNextParamChildNode(node: node, index: &argIndex, kind: kind, depth: depth)
                printer("'")
                printer("]")
            case .ConstantPropKeyPath:
                printer("[")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer(" : ")
                try printNextParamChildNode(node: node, index: &argIndex, kind: kind, depth: depth)
                printer("<")
                try printNextParamChildNode(node: node, index: &argIndex, kind: kind, depth: depth)
                printer(",")
                try printNextParamChildNode(node: node, index: &argIndex, kind: kind, depth: depth)
                printer(">]")
            case .ConstantPropStruct:
                printer("[")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer(" : ")
                try printNextParamChildNode(node: node, index: &argIndex, kind: kind, depth: depth)
                printer("]")
            case .ClosureProp,
                    .EscapingClosureProp:
                if index + 2 > endIndex { return }
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
            case .ClosurePropPreviousArg:
                if index + 2 > endIndex { return }
                printer("[")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer(" ")
                try printNode(node.children(index), depth: depth + 1)
                index += 1
                printer("]")
            }
        }
    }
    
    /// Prints the next child of `node` that is neither a param kind nor a param payload,
    /// starting at `index`, formatted for the constant propagation `kind`.
    mutating func printNextParamChildNode(node: Node, index: inout Int, kind: FunctionSigSpecializationParamKind.Kind, depth: Int) throws {
        while index < node.numberOfChildren {
            let child = node.children(index)
            index += 1
            if child.kind == .FunctionSignatureSpecializationParamKind || child.kind == .FunctionSignatureSpecializationParamPayload {
                continue
            }
            switch kind {
            case .ConstantPropInteger, .ConstantPropFloat:
                guard child.hasText else { return }
                let text = child.text
                let demangleName = try demangleNested(text)
                printer(demangleName.emptyToNil() ?? text)
            case .ConstantPropString:
                if child.hasText {
                    let text = child.text
                    if text.first == "_" {
                        // A "_" escapes a leading digit or "_" of a string constant.
                        printer(String(text.dropFirst()))
                        return
                    }
                }
                try printNode(child, depth: depth + 1)
            case .ConstantPropFunction, .ConstantPropGlobal:
                let text = child.text
                let demangleName = try demangleNested(text)
                printer(demangleName.emptyToNil() ?? text)
            default:
                try printNode(child, depth: depth + 1)
            }
            return
        }
    }
}
