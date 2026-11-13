//
//  Node+Debugging.swift
//  Demangling
//

import Foundation

// MARK: - Debugging
extension Node: CustomDebugStringConvertible {
    
    public var debugDescription: String { printHierarchy() }
    
    public func dump() {
        print(printHierarchy())
    }
    
    // Node와 그 자식들의 kind와 계층 관계를 출력하는 메서드
    func printHierarchy(level: Int = 0) -> String {
        var descriptions: [String] = []
        let prefix = Array<String>(repeating: "\t", count: level).joined()
        
        if payload.hasValue {
            descriptions.append(prefix + "kind=\(kind.rawValue), \(payload)")
        } else {
            descriptions.append(prefix + "kind=\(kind.rawValue)")
        }
        
        if numberOfChildren > 0 {
            for child in copyOfChildren {
                descriptions.append(child.printHierarchy(level: level + 1))
            }
        }
        
        return descriptions.joined(separator: "\n")
    }
}
