//
//  OldDemangler+Helpers.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    func demangleChildOrReturn(parent node: Node, kind: Node.Kind) -> Node? {
        switch kind {
        case .Global:
            if let global = demangleGlobal() {
                return node.adding(global)
            } else {
                return nil
            }
        case .Type:
            if let type = demangleType() {
                return node.adding(type)
            } else {
                return nil
            }
        case .ProtocolConformance:
            if let protoConfo = demangleProtocolConformance() {
                return node.adding(protoConfo)
            } else {
                return nil
            }
        default:
            break
        }
        return nil
    }
    
    func demangleChildAsNodeOrReturn(parent node: Node, kind: Node.Kind) -> Node? {
        switch kind {
        case .Directness:
            if let directness = demangleDirectness() {
                return node.adding(Node(kind: kind, payload: .directness(directness)))
            } else {
                return nil
            }
        default:
            break
        }
        return nil
    }
}
