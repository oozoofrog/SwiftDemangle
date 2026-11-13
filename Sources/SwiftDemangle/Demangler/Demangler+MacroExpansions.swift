//
//  Demangler+MacroExpansions.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleMacroExpansion() -> Node? {
        let kind: Node.Kind
        let isAttached: Bool
        let isFreestanding: Bool
        switch (nextChar()) {
        case "a":
            kind = .AccessorAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "r":
            kind = .MemberAttributeAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "m":
            kind = .MemberAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "p":
            kind = .PeerAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "c":
            kind = .ConformanceAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "e":
            kind = .ExtensionAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "b":
            kind = .BodyAttachedMacroExpansion
            isAttached = true
            isFreestanding = false
        case "f":
            kind = .FreestandingMacroExpansion
            isAttached = false
            isFreestanding = true
        case "u":
            kind = .MacroExpansionUniqueName
            isAttached = false
            isFreestanding = false
        case "X":
            kind = .MacroExpansionLoc
            let line = demangleIndex()
            let col = demangleIndex()
            let lineNode = createNode(.Index, line)
            let colNode = createNode(.Index, col)
            let buffer = popNode(.Identifier)
            let module = popNode(.Identifier)
            return createWithChildren(kind, module, buffer, lineNode, colNode)
        default:
            return nil
        }
        
        let macroName = popNode(.Identifier)
        var privateDiscriminator: Node?
        if isFreestanding {
            privateDiscriminator = popNode(.PrivateDeclName)
        }
        var attachedName: Node?
        if isAttached {
            attachedName = popNode(isDeclName)
        }
        
        var context = popNode { kind in
            kind.isMacroExpansion
        }
        
        if context == nil {
            context = popContext()
        }
        let discriminator = demangleIndexAsNode()
        var result: Node?
        if isAttached {
            result = createWithChildren(
                kind, context, attachedName, macroName, discriminator)
        } else {
            result = createWithChildren(kind, context, macroName, discriminator)
        }
        if let privateDiscriminator {
            result?.add(privateDiscriminator)
        }
        return result
    }
}
