//
//  OldDemangler+Specialization.swift
//  Demangling
//

import Foundation

extension OldDemangler {
    func demangleGenericSpecialization(_ specialization: Node) -> Node? {
        let specialization = specialization
        while !nextIf("_") {
            // Otherwise, we have another parameter. Demangle the type.
            let param = Node(kind: .GenericSpecializationParam)
            if let type = demangleType() {
                param.add(type)
            } else {
                return nil
            }
            
            // Then parse any conformances until we find an underscore. Pop off the
            // underscore since it serves as the end of our mangling list.
            while !nextIf("_") {
                if let protoConfo = demangleProtocolConformance() {
                    param.add(protoConfo)
                } else {
                    return nil
                }
            }
            
            // Add the parameter to our specialization list.
            specialization.add(param)
        }
        
        return specialization
    }
    
    func demangleFuncSigSpecializationConstantProp(parent: inout Node) -> Bool {
        // Then figure out what was actually constant propagated. First check if
        // we have a function.
        
        if nextIf("fr") {
            // Demangle the identifier
            guard let name = demangleIdentifier(), nextIf("_") else { return false }
            parent.addFunctionSigSpecializationParamKind(kind: .ConstantPropFunction)
            parent.add(Node(kind: .Identifier, text: name.text))
            return true
        }
        
        if nextIf("g") {
            guard let name = demangleIdentifier(), nextIf("_") else { return false }
            parent.addFunctionSigSpecializationParamKind(kind: .ConstantPropGlobal)
            parent.add(Node(kind: .Identifier, text: name.text))
            return true
        }
        
        if nextIf("i") {
            guard let str = readUntil("_").emptyToNil(), nextIf("_") else { return false }
            parent.addFunctionSigSpecializationParamKind(kind: .ConstantPropInteger, texts: str)
            return true
        }
        
        if nextIf("fl") {
            guard let str = readUntil("_").emptyToNil(), nextIf("_") else { return false }
            parent.addFunctionSigSpecializationParamKind(kind: .ConstantPropFloat, texts: str)
            return true
        }
        
        if nextIf("s") {
            // Skip: 'e' encoding 'v' str. encoding is a 0 or 1 and str is a string of
            // length less than or equal to 32. We do not specialize strings with a
            // length greater than 32.
            guard nextIf("e") else { return false }
            let encoding = peekChar()
            guard encoding == "0" || encoding == "1" else { return false }
            let encodingStr: String
            if encoding == "0" {
                encodingStr = "u8"
            } else {
                encodingStr = "u16"
            }
            advanceOffset(1)
            
            guard nextIf("v") else { return false }
            guard let str = demangleIdentifier(), nextIf("_") else { return false }
            parent.addFunctionSigSpecializationParamKind(kind: .ConstantPropString, texts: encodingStr)
            parent.add(Node(kind: .Identifier, text: str.text))
            return true
        }
        
        // Unknown constant prop specialization
        return false
    }
    
    func demangleFuncSigSpecializationClosureProp(parent: inout Node) -> Bool {
        // We don't actually demangle the function or types for now. But we do want
        // to signal that we specialized a closure.
        guard let name = demangleIdentifier() else { return false }
        
        parent.addFunctionSigSpecializationParamKind(kind: .ClosureProp, texts: name.text)
        
        // Then demangle types until we fail.
        while peekChar() != "_", let type = demangleType() {
            parent.add(type)
        }
        
        // Eat last '_'
        guard nextIf("_") else { return false }
        
        return true
    }
    
    func demangleFunctionSignatureSpecialization(_ specialization: Node) -> Node? {
        let specialization = specialization
        // Until we hit the last '_' in our specialization info...
        while !nextIf("_") {
            // Create the parameter.
            var param = Node(kind: .FunctionSignatureSpecializationParam)
            
            // First handle options.
            if nextIf("n_") {
                // Leave the parameter empty.
            } else if nextIf("cp") {
                guard demangleFuncSigSpecializationConstantProp(parent: &param) else { return nil }
            } else if nextIf("cl") {
                guard demangleFuncSigSpecializationClosureProp(parent: &param) else { return nil }
            } else if nextIf("i_") {
                param.add(Node(kind: .FunctionSignatureSpecializationParamKind, functionParamKind: .BoxToValue))
            } else if nextIf("k_") {
                param.add(Node(kind: .FunctionSignatureSpecializationParamKind, functionParamKind: .BoxToStack))
            } else {
                // Otherwise handle option sets.
                var value: FunctionSigSpecializationParamKind.OptionSet = .init()
                if nextIf("d") {
                    value.insert(.Dead)
                }
                
                if nextIf("g") {
                    value.insert(.OwnedToGuaranteed)
                }
                
                if nextIf("o") {
                    value.insert(.GuaranteedToOwned)
                }
                
                if nextIf("s") {
                    value.insert(.SROA)
                }
                
                guard nextIf("_") else { return nil }
                
                guard !value.isEmpty else { return nil }

                param.add(Node(kind: .FunctionSignatureSpecializationParamKind, functionParamOption: value))
            }
            
            specialization.add(param)
        }
        
        return specialization
    }
    
    
    func demangleSpecializedAttribute() -> Node? {
        var isNotReAbstracted = false
        if nextIf("g") || isNotReAbstracted.changing(nextIf(("r"))) {
            let spec = Node(kind: isNotReAbstracted ? .GenericSpecializationNotReAbstracted : .GenericSpecialization)
            
            // Create a node if the specialization is serialized.
            if nextIf("q") {
                spec.add(.IsSerialized)
            }
            
            // Create a node for the pass id.
            spec.add(Node(kind: .SpecializationPassID, index: nextChar().number(UInt64.self) ?? 0))
            
            // And then mangle the generic specialization.
            return demangleGenericSpecialization(spec)
        }
        if nextIf("f") {
            let spec = Node(kind: .FunctionSignatureSpecialization)
            
            // Create a node if the specialization is serialized.
            if nextIf("q") {
                spec.add(.IsSerialized)
            }
            
            // Add the pass id.
            spec.add(Node(kind: .SpecializationPassID, index: nextChar().number(UInt64.self) ?? 0))
            
            // Then perform the function signature specialization.
            return demangleFunctionSignatureSpecialization(spec)
        }
        
        // We don't know how to handle this specialization.
        return nil
    }
}
