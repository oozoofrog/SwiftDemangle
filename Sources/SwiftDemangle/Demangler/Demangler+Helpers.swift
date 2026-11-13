//
//  Demangler+Helpers.swift
//  Demangling
//

import Foundation

extension Node {
    func addChild(_ node: Node?) {
        node.flatMap(self.add)
    }
    func getText() -> String {
        text
    }
    func getKind() -> Node.Kind {
        kind
    }
    func getFirstChild() -> Node {
        firstChild
    }
    func getChild(_ at: Int) -> Node {
        children(at)
    }
    func getChildOrNil(_ at: Int) -> Node? {
        if at >= 0, at < numberOfChildren {
            return children(at)
        } else {
            return nil
        }
    }
    func getNumChildren() -> Int {
        numberOfChildren
    }
    func removeChildAt(_ at: Int) {
        self.remove(at)
    }
}

prefix func --<N>(_ rhs: inout N) where N: BinaryInteger {
    rhs = rhs.advanced(by: -1)
}

prefix func ++<N>(_ rhs: inout N) where N: BinaryInteger {
    rhs = rhs.advanced(by: 1)
}

extension Optional where Wrapped == Node {
    func reverseChildren() {
        self?.reverseChildren()
    }
    
    func getKind() -> Node.Kind? {
        self?.kind
    }
    
    func add(_ node: Node?) {
        self?.add(node)
    }
    
    func addChild(_ node: Node?) {
        self?.add(node)
    }
    
    func adds<S>(_ nodes: S) where S: Sequence, S.Element == Node? {
        self.adds(nodes.compactMap({ $0 }))
    }
    
    func adds<C>(_ nodes: C) where C: Collection, C.Element == Node {
        self?.adds(nodes)
    }
    
    func getChild(_ at: Int) -> Node? {
        self?.getChild(at)
    }
    
    func getNumChildren() -> Int {
        self?.getNumChildren() ?? 0
    }
    
    func getText() -> String {
        self?.getText() ?? ""
    }
}

extension Array where Element == Node {
    mutating func append(_ node: Node?) {
        guard let node = node else { return }
        self.append(node)
    }
    
    mutating func push_back(_ node: Node) {
        self.append(node)
    }
    
    func size() -> Int { count }
}

extension String {
    func empty() -> Bool { isEmpty }
    func size() -> Int { count }
    
    func substr(_ from: Int) -> String {
        guard from < self.count else { return "" }
        return String(self[from..<self.count])
    }
    
    mutating func push_back(_ character: Character) {
        self.append(character)
    }
}

extension UInt8 {
    var character: Character { Character(.init(self)) }
}
