//
//  Demangler+NodeStack.swift
//  Demangling
//

import Foundation

extension Demangler {
    func addSubstitution(_ node: Node?) {
        guard let node = node else { return }
        substitutions.append(node)
    }
    
    func pushMultiSubstitutions(_ RepeatCount: Int, _ SubstIdx: Int) -> Node? {
        if SubstIdx >= substitutions.size() {
            return nil
        }
        if RepeatCount > maxRepeatCount {
            return nil
        }
        let Nd = substitutions[SubstIdx]
        if RepeatCount > 1 {
            for _ in 0..<RepeatCount - 1 {
                pushNode(Nd)
            }
        }
        return Nd
    }
    
    func getDependentGenericParamType(_ depth: Int, _ index: Int) -> Node? {
        guard depth >= 0, index >= 0 else { return nil }
        
        let paramTy = createNode(.DependentGenericParamType)
        paramTy.addChild(createNode(.Index, depth))
        paramTy.addChild(createNode(.Index, index))
        return paramTy
    }
    
    func pushNode(_ node: Node) {
        nodeStack.append(node)
    }
    
    func nodeConsumesGenericArgs(_ node: Node) -> Bool {
        switch node.getKind() {
        case .Variable,
                .Subscript,
                .ImplicitClosure,
                .ExplicitClosure,
                .DefaultArgumentInitializer,
                .Initializer,
                .PropertyWrapperBackingInitializer,
                .PropertyWrappedFieldInitAccessor,
                .PropertyWrapperInitFromProjectedValue,
                .Static:
            return false
        default:
            return true
        }
    }
    
    func popNode() -> Node? {
        guard nodeStack.isNotEmpty else { return nil }
        return nodeStack.removeLast()
    }
    
    func popNode(_ kind: Node.Kind) -> Node? {
        guard nodeStack.isNotEmpty else { return nil }
        
        if let lastKind = nodeStack.last?.kind {
            if lastKind != kind {
                return nil
            } else {
                return popNode()
            }
        } else {
            return nil
        }
    }
    
    func popNode(_ pred: (Node.Kind) -> Bool) -> Node? {
        guard nodeStack.isNotEmpty else { return nil }
        if let kind = nodeStack.last?.kind {
            if !pred(kind) {
                return nil
            } else {
                return popNode()
            }
        } else {
            return nil
        }
    }
    
    func popNode(_ keyPath: KeyPath<Node.Kind, Bool>) -> Node? {
        guard nodeStack.isNotEmpty else { return nil }
        
        if let kind = nodeStack.last?.kind {
            if !kind[keyPath: keyPath] {
                return nil
            } else {
                return popNode()
            }
        } else {
            return nil
        }
    }
    
    func popModule() -> Node? {
        if let Ident = popNode(.Identifier) {
            return changeKind(Ident, .Module)
        }
        return popNode(.Module)
    }
    
    func popContext() -> Node? {
        if let mod = popModule() {
            return mod
        }
        if let Ty = popNode(.Type) {
            if Ty.getNumChildren() != 1 {
                return nil
            }
            
            let Child = Ty.getFirstChild()
            if !Child.getKind().isContext {
                return nil
            }
            return Child
        }
        return popNode(isContext)
    }
    
    func popTypeAndGetChild() -> Node? {
        guard let Ty = popNode(.Type), Ty.numberOfChildren == 1 else { return nil }
        return Ty.getFirstChild()
    }
    
    func popTypeAndGetAnyGeneric() -> Node? {
        if let child = popTypeAndGetChild(), child.getKind().isAnyGeneric {
            return child
        }
        return nil
    }
}
