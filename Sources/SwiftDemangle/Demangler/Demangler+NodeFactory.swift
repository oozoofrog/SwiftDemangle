//
//  Demangler+NodeFactory.swift
//  Demangling
//

import Foundation

extension Demangler {
    @discardableResult
    func addChild(_ parent: Node?, _ child: Node?) -> Node? {
        guard let parent = parent, let child = child else { return nil }
        return parent.adding(child)
    }
    
    func createNode(_ kind: Node.Kind) -> Node {
        Node(kind)
    }
    
    func createNode<N>(_ kind: Node.Kind, _ index: N) -> Node where N: BinaryInteger{
        Node(kind, index)
    }
    
    func createNode(_ kind: Node.Kind, _ text: String) -> Node {
        Node(kind: kind, text: text)
    }
    
    func createNode(_ kind: Node.Kind, _ character: Character) -> Node {
        Node(kind: kind, text: character.description)
    }
    
    func createNode(_ kind: Node.Kind, _ directness: Node.Directness) -> Node {
        Node(kind: kind, payload: .directness(directness))
    }
    
    func createNode(_ kind: Node.Kind, _ valueWitnessKind: Node.ValueWitnessKind) -> Node {
        Node(kind, .valueWitnessKind(valueWitnessKind))
    }
    
    func createNode(_ kind: Node.Kind, _ functionSigSpecializationParamKind: FunctionSigSpecializationParamKind) -> Node {
        Node(kind, .functionSigSpecializationParamKind(functionSigSpecializationParamKind))
    }
    
    func createNode(_ kind: Node.Kind, _ functionSigSpecializationParamKindKind: FunctionSigSpecializationParamKind.Kind) -> Node {
        Node(kind, .functionSigSpecializationParamKind(functionSigSpecializationParamKindKind.createFunctionSigSpecializationParamKind()))
    }
    
    func createNode(_ kind: Node.Kind, _ functionSigSpecializationParamKindOption: FunctionSigSpecializationParamKind.OptionSet) -> Node {
        Node(kind, .functionSigSpecializationParamKind(functionSigSpecializationParamKindOption.createFunctionSigSpecializationParamKind()))
    }
    
    func createNode(_ kind: Node.Kind, _ mangledDifferentiabilityKind: MangledDifferentiabilityKind) -> Node {
        Node(kind: kind, payload: .mangledDifferentiabilityKind(mangledDifferentiabilityKind))
    }
    
    func createWithChild(_ kind: Node.Kind, _ child: Node?) -> Node? {
        guard let child = child else { return nil }
        return createNode(kind).adding(child)
    }
    
    func createNodeWithAllocatedText(_ kind: Node.Kind, _ text: String) -> Node? {
        Node(kind: kind, text: text)
    }
    
    func createType(_ child: Node?) -> Node? {
        createWithChild(.Type, child)
    }
    
    func createWithChildren(_ kind: Node.Kind, _ children: Node?...) -> Node? {
        let flatten = children.flatten()
        guard flatten.count == children.count else { return nil }
        return createNode(kind).adding(flatten)
    }
    
    func createSwiftType(_ typeKind: Node.Kind, _ name: String) -> Node? {
        return createType(createWithChildren(typeKind, Node(.Module, .text(.STDLIB_NAME)), Node(.Identifier, .text(name))))
    }
    
    func createStandardSubstitution(_ Subst: Character, _ SecondLevel: Bool) -> Node? {
        if !SecondLevel {
            for st in StandardType.allCases where st.rawValue == Subst {
                return createSwiftType(st.kind, st.typeName)
            }
        }
        if SecondLevel {
            for st in StandardTypeConcurrency.allCases where st.rawValue == Subst {
                return createSwiftType(st.kind, st.typeName)
            }
        }
        return nil
    }
    
    func createWithPoppedType(_ kind: Node.Kind) -> Node? {
        return createWithChild(kind, popNode(.Type))
    }
    
    func changeKind(_ node: Node?, _ newKind: Node.Kind) -> Node? {
        guard let node = node else { return nil }
        let newNode: Node
        if node.hasText {
            newNode = Node(newKind, .text(node.text))
        } else if let index = node.index {
            newNode = Node(newKind, index)
        } else {
            newNode = Node(newKind)
        }
        newNode.adds(node.copyOfChildren)
        return newNode
    }
    
    func addFuncSpecParamNumber(_ Param: Node?, _ Kind: FunctionSigSpecializationParamKind.Kind) -> Node? {
        addFuncSpecParamNumber(Param, Kind.createFunctionSigSpecializationParamKind())
    }
    
    func addFuncSpecParamNumber(_ Param: Node?, _ Kind: FunctionSigSpecializationParamKind) -> Node? {
        Param?.addChild(createNode(.FunctionSignatureSpecializationParamKind, Kind))
        var str = ""
        while peekChar().isNumber {
            str.append(nextChar())
        }
        if str.isEmpty {
            return nil
        }
        return addChild(Param, createNode(.FunctionSignatureSpecializationParamPayload, str))
    }
    
    func isDeclName(_ kind: Node.Kind) -> Bool {
        kind.isDeclName
    }
    
    func isContext(_ kind: Node.Kind) -> Bool {
        kind.isContext
    }
    
    func isRequirement(_ kind: Node.Kind) -> Bool {
        kind.isRequirement
    }
    
    func isEntity(_ kind: Node.Kind) -> Bool {
        kind.isEntity
    }
    
    func isFunctionAttr(_ kind: Node.Kind) -> Bool {
        kind.isFunctionAttr
    }
}
