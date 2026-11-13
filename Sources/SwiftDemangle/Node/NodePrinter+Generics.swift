//
//  NodePrinter+Generics.swift
//  Demangling
//

import Foundation

extension NodePrinter {
    
    mutating func printBoundGenericNoSugar(node: Node, depth: Int) throws {
        guard node.numberOfChildren > 1 else {
            return
        }
        let typelist = node.children(1)
        try printNode(node.children(0), depth: depth + 1)
        printer("<")
        try printChildren(typelist, depth: depth, separator: ", ")
        printer(">")
    }
    
    mutating func printBoundGeneric(node: Node, depth: Int) throws {
        guard node.numberOfChildren > 1 else {
            return
        }
        guard node.numberOfChildren == 2 else {
            try printBoundGenericNoSugar(node: node, depth: depth)
            return
        }
        
        if !options.contains(.synthesizeSugarOnTypes) || node.kind == .BoundGenericClass {
            // no sugar here
            try printBoundGenericNoSugar(node: node, depth: depth)
            return
        }
        
        // Print the conforming type for a "bound" protocol node "as" the protocol
        // type.
        guard node.kind != .BoundGenericProtocol else {
            try printChildren(node.children(1), depth: depth)
            printer(" as ")
            try printNode(node.children(0), depth: depth + 1)
            return
        }
        
        let sugarType = findSugar(node)
        
        switch sugarType {
        case .none:
            try printBoundGenericNoSugar(node: node, depth: depth)
        case .optional,
                .implicitlyUnwrappedOptional:
            let type = node.children(1).children(0)
            try printWithParens(type, depth: depth)
            printer(sugarType == .optional ? "?" : "!")
        case .array:
            let type = node.children(1).children(0)
            printer("[")
            try printNode(type, depth: depth + 1)
            printer("]")
        case .dictionary:
            let keyType = node.children(1).children(0)
            let valueType = node.children(1).children(1)
            printer("[")
            try printNode(keyType, depth: depth + 1)
            printer(" : ")
            try printNode(valueType, depth: depth + 1)
            printer("]")
            break
        }
    }
    
    mutating func printGenericSignature(node: Node, depth: Int) throws {
        printer("<")
        
        let numChildren = node.numberOfChildren
        
        let numGenericParams = node.copyOfChildren.prefix { $0.kind == .DependentGenericParamCount }.count
        
        var firstRequirement = numGenericParams
        while firstRequirement < numChildren {
            var child = node.children(firstRequirement)
            if child.kind == .Type {
                child = child.children(0)
            }
            if child.kind != .DependentGenericParamPackMarker &&
                child.kind != .DependentGenericParamValueMarker {
                break
            }
            firstRequirement += 1
        }
        
        func isGenericParamPack(depth: UInt64, index: UInt64, numGenericParams: Int, firstRequirement: Int) -> Bool {
            for i in numGenericParams..<firstRequirement {
                var child = node.children(i)
                if child.kind != .DependentGenericParamPackMarker {
                    continue
                }
                child = child.children(0)
                
                if child.kind != .Type {
                    continue
                }
                
                child = child.children(0)
                if child.kind != .DependentGenericParamType {
                    continue
                }
                
                if index == child.children(0).index &&
                    depth == child.children(1).index {
                    return true
                }
            }
            
            return false
        }
        
        func isGenericParamValue(depth: UInt64, index: UInt64, numGenericParams: Int, firstRequirement: Int) -> (Bool, Node?) {
            for i in numGenericParams..<firstRequirement {
                var child = node.children(i)
                if child.kind != .DependentGenericParamValueMarker {
                    continue
                }
                child = child.children(0)
                
                if child.kind != .Type {
                    continue
                }
                
                let param = child.children(0)
                // A Type node has one child; NodePrinter.cpp gets null here and prints no value type.
                let type = child.getChildOrNil(1)
                if param.kind != .DependentGenericParamType {
                    continue
                }
                
                if index == param.children(0).index &&
                    depth == param.children(1).index {
                    return (true, type)
                }
            }
            
            return (false, nil)
        }
        
        for gpDepth in 0..<numGenericParams {
            if gpDepth != 0 {
                printer("><")
            }
            if let count = node.children(gpDepth).index {
                for index in 0..<count {
                    if index != 0 {
                        printer(", ")
                    }
                    
                    if (index >= 128) {
                        printer("...")
                        break
                    }
                    
                    if isGenericParamPack(depth: UInt64(gpDepth), index: index, numGenericParams: numGenericParams, firstRequirement: firstRequirement) {
                        printer("each ")
                    }
                    let (isValue, value) = isGenericParamValue(depth: UInt64(gpDepth), index: index, numGenericParams: numGenericParams, firstRequirement: firstRequirement)
                    
                    if isValue {
                        printer("let ")
                    }
                    printer(options.genericParameterName(depth: UInt64(gpDepth), index: index))
                    
                    if let node = value {
                        printer(": ")
                        try printNode(node, depth: depth + 1)
                    }
                }
            }
        }
        
        if firstRequirement != numChildren {
            if options.contains(.displayWhereClauses) {
                printer(" where ")
                for i in firstRequirement..<numChildren {
                    if i > firstRequirement {
                        printer(", ")
                    }
                    try printNode(node.children(i), depth: depth + 1)
                }
            }
        }
        printer(">")
    }
    
    func genericParameterName(depth: UInt64, index: UInt64) -> String {
        var name = ""
        var index = index
        repeat {
            // A(65) + index
            if let scalar = UnicodeScalar(65) {
                name.append(String(scalar))
            }
            index /= 26
        } while index > 0
        if depth > 0 {
            name.append(depth.description)
        }
        return name
    }
}
