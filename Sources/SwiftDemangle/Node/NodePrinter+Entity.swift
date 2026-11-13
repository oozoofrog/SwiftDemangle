//
//  NodePrinter+Entity.swift
//  Demangling
//

import Foundation

extension NodePrinter {
    
    @discardableResult
    mutating func printEntity(entity: Node,
                                      depth: Int,
                                      asPrefixContext: Bool,
                                      typePrinting: TypePrinting,
                                      hasName: Bool,
                                      extraName: String? = nil,
                                      extraIndex: Int = -1,
                                      overwriteName: String? = nil) throws -> Node? {
        var entity = entity
        var typePrinting = typePrinting
        var extraIndex = extraIndex
        var extraName = extraName
        var genericFunctionTypeList: Node?
        if entity.kind == .BoundGenericFunction {
            genericFunctionTypeList = entity.children(1)
            entity = entity.children(0)
        }
        // Either we print the context in prefix form "<context>.<name>" or in
        // suffix form "<name> in <context>".
        var multiWordName = extraName?.contains(" ") ?? false
        // Also a local name (e.g. Mystruct #1) does not look good if its context is
        // printed in prefix form.
        let localName = hasName && entity.children(1).kind == .LocalDeclName
        if localName, options.contains(.displayLocalNameContexts) {
            multiWordName = true
        }
        if asPrefixContext && (typePrinting != .noType || multiWordName) {
            // If the context has a type to be printed, we can't use the prefix form.
            return entity
        }
        var postfixContext: Node?
        let context = entity.children(0)
        
        if printContext(context) {
            if multiWordName {
                // If the name contains some spaces we don't print the context now but
                // later in suffix form.
                postfixContext = context
            } else {
                let currentPosition = printText.utf8.count
                postfixContext = try printNode(context, depth: depth + 1, asPrefixContext: true)
                
                // Was the context printed as prefix?
                if printText.utf8.count != currentPosition {
                    printer(".")
                }
            }
        }
        if hasName || overwriteName.isNotEmpty {
            if let name = extraName?.emptyToNil(), multiWordName {
                printer(name)
                if extraIndex >= 0 {
                    printerIndex(extraIndex)
                }
                printer(" of ")
                extraName = ""
                extraIndex = -1
            }
            let currentPos = printText.utf8.count
            if let name = overwriteName?.emptyToNil() {
                printer(name)
            } else {
                let name = entity.children(1)
                if name.kind != .PrivateDeclName {
                    try printNode(name, depth: depth + 1)
                }
                if let privateName = entity.childIf(.PrivateDeclName) {
                    try printNode(privateName, depth: depth + 1)
                }
            }
            if printText.utf8.count != currentPos, extraName.isNotEmpty {
                printer(".")
            }
        }
        if let name = extraName?.emptyToNil() {
            printer(name)
            if extraIndex >= 0 {
                printerIndex(extraIndex)
            }
        }
        if typePrinting != .noType {
            guard var type = entity.childIf(.Type) else {
                assertionFailure("malformed entity")
                setInvalid()
                return nil
            }
            type = type.children(0)
            if typePrinting == .functionStyle {
                // We expect to see a function type here, but if we don't, use the colon.
                var t = type
                while t.kind == .DependentGenericType {
                    t = t.children(1).children(0)
                }
                switch t.kind {
                case .FunctionType, .NoEscapeFunctionType, .UncurriedFunctionType, .CFunctionPointer, .ThinFunctionType:
                    break
                default:
                    typePrinting = .withColon
                }
            }
            if typePrinting == .withColon {
                if options.contains(.displayEntityTypes) {
                    printer(" : ")
                    try printEntityType(
                        entity: entity,
                        type: type,
                        genericFunctionTypeList: genericFunctionTypeList,
                        depth: depth
                    )
                }
            } else {
                assert(typePrinting == .functionStyle)
                if multiWordName || needSpaceBeforeType(type: type) {
                    printer(" ")
                }
                try printEntityType(
                    entity: entity,
                    type: type,
                    genericFunctionTypeList: genericFunctionTypeList,
                    depth: depth
                )
            }
        }
        
        if !asPrefixContext, let context = postfixContext, (!localName || options.contains(.displayLocalNameContexts)) {
            switch entity.kind {
            case .DefaultArgumentInitializer,
                    .Initializer,
                    .PropertyWrapperBackingInitializer,
                    .PropertyWrappedFieldInitAccessor,
                    .PropertyWrapperInitFromProjectedValue:
                printer(" of ")
            default:
                printer(" in ")
            }
            try printNode(context, depth: depth + 1)
            postfixContext = nil
        }
        return postfixContext
    }
    
    mutating func printEntityType(entity: Node, type: Node, genericFunctionTypeList: Node?, depth: Int) throws {
        let labelList = entity.childIf(.LabelList)
        var type = type
        if labelList != nil || genericFunctionTypeList != nil {
            if let node = genericFunctionTypeList {
                printer("<")
                try printChildren(node, depth: depth, separator: ", ")
                printer(">")
            }
            if type.kind == .DependentGenericType {
                if genericFunctionTypeList == nil {
                    try printNode(type.children(0), depth: depth + 1) // generic signature
                }
                let dependentType = type.children(1)
                if (needSpaceBeforeType(type: dependentType)) {
                    printer(" ")
                }
                type = dependentType.children(0)
            }
            
            try printFunctionType(labelList: labelList, type: type, depth: depth)
        } else {
            try printNode(type, depth: depth + 1)
        }
    }
    
    func printContext(_ context: Node) -> Bool {
        if !options.contains(.qualifyEntities) {
            return false
        }
        if context.kind == .Module {
            if context.text == .STDLIB_NAME {
                return options.contains(.displayStdlibModule)
            }
            if context.text == .MANGLING_MODULE_OBJC {
                return options.contains(.displayObjCModule)
            }
            if context.text.hasPrefix(.LLDB_EXPRESSIONS_MODULE_NAME_PREFIX) {
                return options.contains(.displayDebuggerGeneratedModule)
            }
        }
        return true
    }
    
    mutating func printAbstractStorage(node: Node, depth: Int, asPrefixContext: Bool, extraName: String) throws -> Node? {
        switch node.kind {
        case .Variable:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .withColon,
                hasName: true,
                extraName: extraName
            )
        case .Subscript:
            return try printEntity(
                entity: node,
                depth: depth,
                asPrefixContext: asPrefixContext,
                typePrinting: .withColon,
                hasName: true,
                extraName: extraName,
                extraIndex: -1,
                overwriteName: "subscript"
            )
        default:
            throw SwiftDemangleError.nodePrinterError(description: "Not an abstract storage node", nodeDebugDescription: node.debugDescription)
        }
    }
}
