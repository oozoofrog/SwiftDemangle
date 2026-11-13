//
//  OldDemangler+Entities.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    func demangleDeclName() -> Node? {
        // decl-name ::= local-decl-name
        // local-decl-name ::= 'L' index identifier
        if nextIf("L") {
            guard let discriminator = demangleIndexAsNode() else { return nil }
            guard let name = demangleIdentifier() else { return nil }
            
            let localName = Node(kind: .LocalDeclName)
            localName.add(discriminator)
            localName.add(name)
            return localName
        } else if nextIf("P") {
            guard let discriminator = demangleIdentifier() else { return nil }
            guard let name = demangleIdentifier() else { return nil }
            
            let privateName = Node(kind: .PrivateDeclName)
            privateName.add(discriminator)
            privateName.add(name)
            return privateName
        }
        
        // decl-name ::= identifier
        return demangleIdentifier()
    }
    
    func demangleModule() -> Node? {
        if nextIf("s") {
            return Node(kind: .Module, text: .STDLIB_NAME)
        }
        if nextIf("S") {
            guard let module = demangleSubstitutionIndex() else { return nil }
            guard module.kind != .Module else { return nil }
            return module
        }
        
        guard let module = demangleIdentifier(kind: .Module) else { return nil }
        substitutions.append(module)
        return module
    }
    
    func demangleDeclarationName(kind: Node.Kind) -> Node? {
        guard let context = demangleContext() else {
            return nil
        }
        guard let name = demangleDeclName() else {
            return nil
        }
        let decl = Node(kind: kind)
        decl.add(context)
        decl.add(name)
        substitutions.append(decl)
        return decl
    }
    
    func demangleProtocolName() -> Node? {
        guard let proto = demangleProtocolNameImpl() else { return nil }
        
        let type = Node(kind: .Type)
        type.add(proto)
        return type
    }
    
    func demangleProtocolNameGivenContext(_ context: Node) -> Node? {
        guard let name = demangleDeclName() else { return nil }
        
        let proto = Node(kind: .Protocol)
        proto.add(context)
        proto.add(name)
        substitutions.append(proto)
        return proto
    }
    
    func demangleProtocolNameImpl() -> Node? {
        // There's an ambiguity in <protocol> between a substitution of
        // the protocol and a substitution of the protocol's context, so
        // we have to duplicate some of the logic from
        // demangleDeclarationName.
        if nextIf("S") {
            guard let sub = demangleSubstitutionIndex() else { return nil }
            if sub.kind == .Protocol {
                return sub
            }
            
            guard sub.kind == .Module else { return nil }
            
            return demangleProtocolNameGivenContext(sub)
        }
        
        if nextIf("s") {
            let stdlib = Node(kind: .Module, text: .STDLIB_NAME)
            return demangleProtocolNameGivenContext(stdlib)
        }
        
        return demangleDeclarationName(kind: .Protocol)
    }
    
    func demangleNominalType() -> Node? {
        if nextIf("S") {
            return demangleSubstitutionIndex()
        }
        if nextIf("V") {
            return demangleDeclarationName(kind: .Structure)
        }
        if nextIf("O") {
            return demangleDeclarationName(kind: .Enum)
        }
        if nextIf("C") {
            return demangleDeclarationName(kind: .Class)
        }
        if nextIf("P") {
            return demangleDeclarationName(kind: .Protocol)
        }
        return nil
    }
    
    func demangleBoundGenericArgs(nominalType: Node) -> Node? {
        var nominalType = nominalType
        // Generic arguments for the outermost type come first.
        guard var parentOrModule = nominalType.copyOfChildren.first else { return nil }

        if ![Node.Kind.Module, .Function, .Extension].contains(parentOrModule.kind) {
            guard let node = demangleBoundGenericArgs(nominalType: parentOrModule) else { return nil }
            parentOrModule = node
            let result = Node(kind: nominalType.kind)
            result.add(parentOrModule)
            result.add(nominalType.children(1))
            nominalType = result
        }
       
        let args = Node(kind: .TypeList)
        while !nextIf("_") {
            guard let type = demangleType() else { return nil }
            args.add(type)
            guard isNotEmpty else { return nil }
        }
        
        // If there were no arguments at this level there is nothing left
        // to do.
        if args.copyOfChildren.isEmpty {
            return nominalType
        }
        
        // Otherwise, build a bound generic type node from the unbound
        // type and arguments.
        let unboundType = Node(kind: .Type)
        unboundType.add(nominalType)
        
        let kind: Node.Kind
        switch nominalType.kind { // look through Type node
        case .Class:
            kind = .BoundGenericClass
        case .Structure:
            kind = .BoundGenericStructure
        case .Enum:
            kind = .BoundGenericEnum
        default:
            return nil
        }
        let result = Node(kind: kind)
        result.add(unboundType)
        result.add(args)
        return result
    }
    
    func demangleBoundGenericType() -> Node? {
        // bound-generic-type ::= 'G' nominal-type (args+ '_')+
        //
        // Each level of nominal type nesting has its own list of arguments.
        guard let nominalType = demangleNominalType() else { return nil }
        return demangleBoundGenericArgs(nominalType: nominalType)
    }
    
    func demangleContext() -> Node? {
      // context ::= module
      // context ::= entity
      // context ::= 'E' module context (extension defined in a different module)
      // context ::= 'e' module context generic-signature (constrained extension)
        depth += 1
        defer { depth -= 1 }
        guard depth <= maxDepth else { return nil }
        guard isNotEmpty else { return nil }
        if nextIf("E") {
            guard let def_module = demangleModule() else { return nil }
            guard let type = demangleContext() else { return nil }
            let ext = Node(kind: .Extension)
            ext.add(def_module)
            ext.add(type)
            return ext
        }
        if nextIf("e") {
            guard let def_module = demangleModule() else { return nil }
            // The generic context is currently re-specified by the type mangling.
            // If we ever remove 'self' from manglings, we should stop resetting the
            // context here.
            guard let sig = demangleGenericSignature() else { return nil }
            guard let type = demangleContext() else { return nil }
            let ext = Node(kind: .Extension)
            ext.add(def_module)
            ext.add(type)
            ext.add(sig)
            return ext
        }
        if nextIf("S") {
            return demangleSubstitutionIndex()
        }
        if nextIf("s") {
            return Node(kind: .Module, text: .STDLIB_NAME)
        }
        if nextIf("G") {
            return demangleBoundGenericType()
        }
        if isStartOfEntity(peekChar()) {
            return demangleEntity()
        } else {
            return demangleModule()
        }
    }
    
    func demangleProtocolList() -> Node? {
        let proto_list = Node(kind: .ProtocolList)
        let type_list = Node(kind: .TypeList)
        while !nextIf("_") {
            guard let proto = demangleProtocolName() else { return nil }
            type_list.add(proto)
        }
        proto_list.add(type_list)
        return proto_list
    }
    
    func demangleProtocolConformance() -> Node? {
        guard let type = demangleType() else { return nil }
        guard let protocolName = demangleProtocolName() else { return nil }
        guard let context = demangleContext() else { return nil }
        let protocolConformance = Node(kind: .ProtocolConformance)
        protocolConformance.add(type)
        protocolConformance.add(protocolName)
        protocolConformance.add(context)
        return protocolConformance
    }
    
    // entity ::= entity-kind context entity-name
    // entity ::= nominal-type
    func demangleEntity() -> Node? {
        // static?
        let isStatic = nextIf("Z")
        
        // entity-kind
        let entityBasicKind: Node.Kind
        if nextIf("F") {
            entityBasicKind = .Function
        } else if nextIf("v") {
            entityBasicKind = .Variable
        } else if nextIf("I") {
            entityBasicKind = .Initializer
        } else if nextIf("i") {
            entityBasicKind = .Subscript
        } else {
            return demangleNominalType()
        }
        
        guard let context = demangleContext() else { return nil }
        
        // entity-name
        let entityKind: Node.Kind
        var hasType = true
        // Wrap the enclosed entity in a variable or subscript node
        var wrapEntity = false
        var name: Node?
        if nextIf("D") {
            entityKind = .Deallocator
            hasType = false
        } else if nextIf("Z") {
            entityKind = .IsolatedDeallocator;
            hasType = false
        } else if nextIf("d") {
            entityKind = .Destructor
            hasType = false
        } else if nextIf("e") {
            entityKind = .IVarInitializer
            hasType = false
        } else if nextIf("E") {
            entityKind = .IVarDestroyer
            hasType = false
        } else if nextIf("C") {
            entityKind = .Allocator
        } else if nextIf("c") {
            entityKind = .Constructor
        } else if nextIf("a") {
            wrapEntity = true
            if nextIf("O") {
                entityKind = .OwningMutableAddressor
            } else if nextIf("o") {
                entityKind = .NativeOwningMutableAddressor
            } else if nextIf("p") {
                entityKind = .NativePinningMutableAddressor
            } else if nextIf("u") {
                entityKind = .UnsafeMutableAddressor
            } else {
                return nil
            }
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("l") {
            wrapEntity = true
            if nextIf("O") {
                entityKind = .OwningAddressor
            } else if nextIf("o") {
                entityKind = .NativeOwningAddressor
            } else if nextIf("p") {
                entityKind = .NativePinningAddressor
            } else if nextIf("u") {
                entityKind = .UnsafeAddressor
            } else {
                return nil
            }
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("g") {
            wrapEntity = true
            entityKind = .Getter
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("G") {
            wrapEntity = true
            entityKind = .GlobalGetter
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("s") {
            wrapEntity = true
            entityKind = .Setter
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("m") {
            wrapEntity = true
            entityKind = .MaterializeForSet
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("w") {
            wrapEntity = true
            entityKind = .WillSet
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("W") {
            wrapEntity = true
            entityKind = .DidSet
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("r") {
            wrapEntity = true
            entityKind = .ReadAccessor
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("M") {
            wrapEntity = true
            entityKind = .ModifyAccessor
            guard let node = demangleDeclName() else { return nil }
            name = node
        } else if nextIf("U") {
            entityKind = .ExplicitClosure
            guard let node = demangleIndexAsNode() else { return nil }
            name = node
        } else if nextIf("u") {
            entityKind = .ImplicitClosure
            guard let node = demangleIndexAsNode() else { return nil }
            name = node
        } else if (entityBasicKind == .Initializer) {
            if nextIf("A") { // entity-name ::= 'A' index
                entityKind = .DefaultArgumentInitializer
                guard let node = demangleIndexAsNode() else { return nil }
                name = node
            } else if nextIf("i") { // entity-name ::= 'i'
                entityKind = .Initializer
            } else {
                return nil
            }
            hasType = false
        } else {
            entityKind = entityBasicKind
            guard let node = demangleDeclName() else { return nil }
            name = node
        }
        
        let entity = Node(kind: entityKind)
        if wrapEntity {
            // Create a subscript or variable node and make it the accessor's child
            var wrappedEntity: Node
            var isSubscript = false
            
            // Rewrite the subscript's name to match the new mangling scheme
            switch name?.kind {
            case .Identifier:
                if name?.text == "subscript" {
                    isSubscript = true
                    // Subscripts have no 'subscript' identifier name
                    name = nil
                }
            case .PrivateDeclName: // identifier file-discriminator?
                if name.map(\.numberOfChildren).or(0) > 1, name?.children(1).text == "subscript" {
                    isSubscript = true
                    
                    let discriminator = name?.children(0)
                    
                    // Create new PrivateDeclName with no 'subscript' identifier child
                    name = .init(kind: .PrivateDeclName)
                    name?.add(discriminator)
                }
            default:
                break
            }
            
            // Create wrapped entity node
            if isSubscript {
                wrappedEntity = Node(kind: .Subscript)
            } else {
                wrappedEntity = Node(kind: .Variable)
            }
            wrappedEntity.add(context)
            
            // Variables mangle their name before their type
            if !isSubscript {
                wrappedEntity.add(name)
            }
            
            if hasType {
                guard let type = demangleType() else { return nil }
                wrappedEntity.add(type)
            }
            
            // Subscripts mangle their file-discriminator after the type
            if isSubscript, let name = name {
                wrappedEntity.add(name)
            }
            
            entity.add(wrappedEntity)
        } else {
            entity.add(context)
            
            if let name = name {
                entity.add(name)
            }
            
            if hasType {
                guard let type = demangleType() else { return nil }
                entity.add(type)
            }
        }
        
        if isStatic {
            let staticNode = Node(kind: .Static)
            staticNode.add(entity)
            return staticNode
        }
        
        return entity
    }
}
