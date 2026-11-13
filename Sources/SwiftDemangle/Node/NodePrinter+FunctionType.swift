//
//  NodePrinter+FunctionType.swift
//  Demangling
//

import Foundation

extension NodePrinter {
    
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
            // Reachable with malformed input; NodePrinter.cpp only asserts and goes on printing.
            break
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
        if type.children(startIndex).kind == .SendingResultFunctionType {
            startIndex += 1
            hasSendingResult = true
        }
        if type.children(startIndex).kind == .IsolatedAnyFunctionType {
            try printNode(type.children(startIndex), depth: depth + 1)
            startIndex += 1
        }
        var nonIsolatedCallerNode: Node?
        if type.children(startIndex).kind == .NonIsolatedCallerFunctionType {
            nonIsolatedCallerNode = type.children(startIndex)
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

        if let nonIsolatedCallerNode {
            try printNode(nonIsolatedCallerNode, depth: depth + 1)
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
}
