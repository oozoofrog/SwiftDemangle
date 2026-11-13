//
//  Node+Optional.swift
//  Demangling
//

import Foundation

extension Optional where Wrapped == Node {
    var isAlias: Bool {
        if let node = self {
            return node.isAlias
        } else {
            return false
        }
    }
    var isClass: Bool {
        if let node = self {
            return node.isClass
        } else {
            return false
        }
    }
    var isEnum: Bool {
        if let node = self {
            return node.isEnum
        } else {
            return false
        }
    }
    var isProtocol: Bool {
        if let node = self {
            return node.isProtocol
        } else {
            return false
        }
    }
    var isStruct: Bool {
        if let node = self {
            return node.isStruct
        } else {
            return false
        }
    }
}
