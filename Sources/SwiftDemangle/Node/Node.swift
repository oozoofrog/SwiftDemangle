//
//  Node.swift
//  Demangling
//
//  Created by spacefrog on 2021/03/26.
//

import Foundation

public final class Node {

    typealias IndexType = UInt64
    
    /// The kind of syntax represented by this node.
    public private(set) var kind: Kind
    private(set) var payload: Payload
    private(set) var _children: [Node]
    
    /// Edges on the longest path down to a leaf.
    private(set) var height = 0
    
    /// The tallest tree a demangler returns. Deeper input is treated as undemanglable so
    /// that parsing, printing and releasing a tree stay within a 512 KB thread stack.
    static let maxDepth = 256
    
    var copyOfChildren: [Node] { _children }

    /// The child nodes in syntax-tree order. Changing this array does not change the tree.
    public var children: [Node] { copyOfChildren }
    
    var numberOfChildren: Int { _children.count }
    
    init(kind: Kind) {
        self.kind = kind
        self.payload = .none
        self._children = []
    }
    
    convenience init(_ kind: Kind) {
        self.init(kind: kind)
    }
    
    init(kind: Kind, text: String) {
        self.kind = kind
        self.payload = .text(text)
        self._children = []
    }
    
    convenience init(_ kind: Kind, _ character: Character) {
        self.init(kind: kind, text: character.description)
    }
    
    init(kind: Kind, functionParamKind: FunctionSigSpecializationParamKind.Kind) {
        self.kind = kind
        self.payload = .functionSigSpecializationParamKind(.init(kind: functionParamKind))
        self._children = []
    }
    
    init(kind: Kind, functionParamOption: FunctionSigSpecializationParamKind.OptionSet) {
        self.kind = kind
        self.payload = .functionSigSpecializationParamKind(.init(optionSet: functionParamOption))
        self._children = []
    }
    
    init<N>(kind: Kind, index: N) where N: BinaryInteger {
        self.kind = kind
        self.payload = .index(UInt64(truncatingIfNeeded: index))
        self._children = []
    }
    
    convenience init<N>(_ kind: Kind, _ index: N) where N: BinaryInteger {
        self.init(kind: kind, index: index)
    }
    
    init(kind: Kind, payload: Payload) {
        self.kind = kind
        self.payload = payload
        self._children = []
    }
    
    convenience init(_ kind: Kind, _ payload: Payload) {
        self.init(kind: kind, payload: payload)
    }
    
    init(kind: Kind, children: Node?...) {
        self.kind = kind
        self.payload = .none
        self._children = children.flatten()
        self.recomputeHeight()
        self.updatePayloadForChildren()
    }
    
    convenience init(kind: Kind, child: Node?) {
        self.init(kind: kind, children: child)
    }
    
    func newNode(_ kind: Kind) -> Node {
        let node = Node(kind: kind)
        node.payload = payload
        node._children = _children
        node.height = height
        return node
    }
    
    func children(_ at: Int) -> Node {
        if at >= 0, at < self._children.count {
            return self._children[at]
        } else {
            assertionFailure()
            return Node(kind: .UnknownIndex)
        }
    }
    
    func childIf(_ kind: Node.Kind) -> Node? {
        _children.first(where: { $0.kind == kind })
    }
    
    private func updatePayloadForChildren() {
        switch self._children.count {
        case 1:
            payload = .onechild
        case 2:
            payload = .twochildren
        case 3...:
            payload = .manychildren
        default:
            payload = .none
        }
    }
    
    func add(_ child: Node) {
        if payload.isChildren {
            self._children.append(child)
            self.height = max(height, child.height + 1)
            self.updatePayloadForChildren()
        } else {
            assertionFailure("cannot add child to \(self)")
        }
    }
    
    func add(_ childOrNil: Node?) {
        guard let child = childOrNil else { return }
        self.add(child)
    }
    
    func add(_ kind: Node.Kind) {
        add(.init(kind: kind))
    }
    
    func add(kind: Node.Kind, text: String) {
        add(.init(kind: kind, text: text))
    }
    
    func add(kind: Node.Kind, payload: Payload) {
        add(Node(kind: kind, payload: payload))
    }
    
    func adds<C>(_ children: C) where C: Collection, C.Element == Node {
        guard children.isNotEmpty else { return }
        if payload.isChildren {
            self._children.append(contentsOf: children)
            for child in children {
                self.height = max(height, child.height + 1)
            }
            self.updatePayloadForChildren()
        } else {
            assertionFailure("cannot add child to \(self)")
        }
    }
    
    func addFunctionSigSpecializationParamKind(kind: FunctionSigSpecializationParamKind.Kind, texts: String...) {
        add(Node(kind: .FunctionSignatureSpecializationParamKind, functionParamKind: kind))
        for text in texts {
            add(Node(kind: .FunctionSignatureSpecializationParamPayload, text: text))
        }
    }
    
    func adding(_ children: Node?...) -> Self {
        self.adding(children.flatten())
    }
    
    func adding(_ children: [Node]) -> Self {
        self.adds(children)
        return self
    }
    
    func remove(_ child: Node) {
        if let index = _children.firstIndex(where: { $0 === child }) {
            self._children.remove(at: index)
            recomputeHeight()
        }
    }
    
    func remove(_ at: Int) {
        guard at < numberOfChildren else { return }
        self._children.remove(at: at)
        recomputeHeight()
    }
    
    func reverseChildren() {
        _children.reverse()
    }
    
    func reverseChildren(_ fromAt: Int) {
        guard fromAt < numberOfChildren else { return }
        if fromAt == 0 {
            _children.reverse()
        } else {
            let prefix = _children[0..<fromAt]
            let reversedSuffix = _children[fromAt..<_children.count].reversed()
            self._children = Array(prefix) + reversedSuffix
        }
    }
    
    func replaceLast(_ child: Node) {
        self._children.removeLast()
        self._children.append(child)
        recomputeHeight()
    }
    
    /// Recomputes `height` from the children; needed after a mutation that can lower it,
    /// and on the parent of a child that gained children after it was attached.
    func recomputeHeight() {
        height = _children.reduce(0) { max($0, $1.height + 1) }
    }
    
    /// Whether some path below this node has more than `limit` edges. Unlike `height` this
    /// walks the tree, so it does not depend on `height` being up to date.
    func isDeeper(than limit: Int) -> Bool {
        guard limit > 0 else { return _children.isNotEmpty }
        return _children.contains { $0.isDeeper(than: limit - 1) }
    }
    
    /// Detaches every node below this one, so that releasing a deep tree does not recurse.
    func dismantle() {
        var pending = [self]
        while let node = pending.popLast() {
            pending.append(contentsOf: node._children)
            node._children = []
        }
    }
    
    var isSwiftModule: Bool {
        kind == .Module && text == .STDLIB_NAME
    }
    
    func isIdentifier(desired: String) -> Bool {
        kind == .Identifier && text == desired
    }
    
    /// The text payload, or an empty string when this node has no text payload.
    public var text: String {
        if case let .text(text) = self.payload {
            return text
        } else {
            return ""
        }
    }
    
    var hasText: Bool {
        self.payload.isText
    }
    
    /// The numeric payload, or `nil` when this node has no numeric payload.
    public var index: UInt64? {
        switch self.payload {
        case let .index(index):
            return index
        default:
            return nil
        }
    }
    
    var functionSigSpecializationParamKind: FunctionSigSpecializationParamKind? {
        switch self.payload {
        case let .functionSigSpecializationParamKind(kind):
            return kind
        default:
            return nil
        }
    }
    
    var valueWitnessKind: ValueWitnessKind? {
        switch self.payload {
        case let .valueWitnessKind(w):
            return w
        default:
            return nil
        }
    }
    
    var mangledDifferentiabilityKind: MangledDifferentiabilityKind? {
        switch self.payload {
        case let .mangledDifferentiabilityKind(kind):
            return kind
        case let .text(text):
            return MangledDifferentiabilityKind(rawValue: text)
        default:
            return nil
        }
    }
    
    var firstChild: Node {
        children(0)
    }
    
    var lastChild: Node {
        children(_children.endIndex - 1)
    }
    
    var directness: Directness {
        if case let .directness(directness) = self.payload {
            return directness
        } else {
            assertionFailure()
            return .unknown
        }
    }
}
