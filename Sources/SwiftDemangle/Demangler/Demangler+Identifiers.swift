//
//  Demangler+Identifiers.swift
//  Demangling
//

import Foundation

extension Demangler {
    func demangleNatural() -> Int {
        if !peekChar().isNumber {
            return -1000
        }
        var num = 0
        while true {
            let c = peekChar()
            if !c.isNumber {
                return num
            }
            // Upstream parses into a 32-bit int and rejects a value that overflows it.
            let newNum = (10 * num) + (c - "0")
            if newNum > Int(Int32.max) {
                return -1000
            }
            num = newNum
            nextChar()
        }
    }
    
    func demangleIndex() -> Int {
        if nextIf("_") {
            return 0
        }
        let num = demangleNatural()
        if num >= 0 && nextIf("_") {
            return num + 1
        }
        return -1000
    }
    
    func demangleIndexAsNode() -> Node? {
        let Idx = demangleIndex()
        if Idx >= 0 {
            return createNode(.Number, Idx)
        }
        return nil
    }
    
    func demangleMultiSubstitutions() -> Node? {
        var RepeatCount = -1
        while true {
            let c = nextChar()
            if c == .zero {
                // End of text.
                return nil
            }
            if c.isLowercase {
                // It's a substitution with an index < 26.
                guard let Nd = pushMultiSubstitutions(RepeatCount, c - "a") else { return nil }
                pushNode(Nd)
                RepeatCount = -1
                // A lowercase letter indicates that there are more substitutions to
                // follow.
                continue
            }
            if c.isUppercase {
                // The last substitution.
                return pushMultiSubstitutions(RepeatCount, c - "A")
            }
            if c == "_" {
                // The previously demangled number is actually not a repeat count but
                // the large (> 26) index of a substitution. Because it's an index we
                // have to add 27 and not 26.
                let Idx = RepeatCount + 27
                if Idx >= substitutions.size() {
                    return nil
                }
                return substitutions[Idx]
            }
            pushBack()
            // Not a letter? Then it can only be a natural number which might be the
            // repeat count or a large (> 26) substitution index.
            RepeatCount = demangleNatural()
            if RepeatCount < 0 {
                return nil
            }
        }
    }
    
    func demangleStandardSubstitution() -> Node? {
        let c = nextChar()
        switch c {
        case "o":
            return createNode(.Module, .MANGLING_MODULE_OBJC)
        case "C":
            return createNode(.Module, .MANGLING_MODULE_CLANG_IMPORTER)
        case "g":
            let OptionalTy = createType(createWithChildren(.BoundGenericEnum, createSwiftType(.Enum, "Optional"), createWithChild(.TypeList, popNode(.Type))))
            addSubstitution(OptionalTy)
            return OptionalTy
        default:
            pushBack()
            let RepeatCount = demangleNatural()
            if RepeatCount > maxRepeatCount {
                return nil
            }
            let secondLevelSubstitution = nextIf("c")
            if let Nd = createStandardSubstitution(nextChar(), secondLevelSubstitution) {
                if RepeatCount > 1 {
                    for _ in 0..<RepeatCount - 1 {
                        pushNode(Nd)
                    }
                }
                return Nd
            }
            return nil
        }
    }
    
    func demangleIdentifier() -> Node? {
        var hasWordSubsts = false
        var isPunycoded = false
        let c = peekChar()
        if !c.isNumber {
            return nil
        }
        if c == "0" {
            nextChar()
            if peekChar() == "0" {
                nextChar()
                isPunycoded = true
            } else {
                hasWordSubsts = true
            }
        }
        var Identifier = ""
        repeat {
            while hasWordSubsts && peekChar().isLetter {
                let c = nextChar()
                var WordIdx = 0
                if c.isLowercase {
                    WordIdx = c - "a"
                } else {
                    assert(c.isUppercase)
                    WordIdx = c - "A"
                    hasWordSubsts = false
                }
                if WordIdx >= numWords {
                    return nil
                }
                assert(WordIdx < maxNumWords)
                let Slice = words[WordIdx]
                Identifier.append(Slice)
            }
            if nextIf("0") {
                break
            }
            let numChars = demangleNatural()
            if numChars <= 0 {
                return nil
            }
            if isPunycoded {
                nextIf("_")
            }
            if self.position + numChars > buffer.count {
                return nil
            }
            let Slice = slice(numChars)
            if isPunycoded {
                var PunycodedString: String = ""
                if let punycoded = Punycode(string: Slice).decode() {
                    PunycodedString = punycoded
                } else {
                    return nil
                }
                Identifier.append(PunycodedString)
            } else {
                Identifier.append(Slice)
                let SliceChars = Array(Slice)
                var wordStartPos = -1
                for Idx in 0...SliceChars.count {
                    let c: Character = Idx < SliceChars.count ? SliceChars[Idx] : .zero
                    if wordStartPos >= 0 && c.isWordEnd(prevChar: SliceChars[Idx - 1]) {
                        if (Idx - wordStartPos >= 2 && numWords < maxNumWords) {
                            let word = String(SliceChars[wordStartPos..<Idx])
                            self.words.append(word)
                        }
                        wordStartPos = -1
                    }
                    if wordStartPos < 0 && c.isWordStart {
                        wordStartPos = Idx
                    }
                }
            }
            advanceOffset(numChars)
        } while hasWordSubsts
        
        if Identifier.empty() {
            return nil
        }
        let Ident = createNode(.Identifier, Identifier)
        addSubstitution(Ident)
        return Ident
    }
    
    func demangleOperatorIdentifier() -> Node? {
        guard let Ident = popNode(.Identifier) else { return nil }
        
        let op_char_table = "& @/= >    <*!|+?%-~   ^ ."
        
        var OpStr = ""
        for c in Ident.text {
            if c.asciiValue == nil {
                // Pass through Unicode characters.
                OpStr.push_back(c)
                continue
            }
            if !c.isLowercase {
                return nil
            }
            let o = op_char_table[c - "a"]
            if o == " " {
                return nil
            }
            OpStr.push_back(o)
        }
        switch nextChar() {
        case "i": return createNode(.InfixOperator, OpStr)
        case "p": return createNode(.PrefixOperator, OpStr)
        case "P": return createNode(.PostfixOperator, OpStr)
        default: return nil
        }
    }
    
    func demangleLocalIdentifier() -> Node? {
        if nextIf("L") {
            let discriminator = popNode(.Identifier)
            let name = popNode(isDeclName)
            return createWithChildren(.PrivateDeclName, discriminator, name)
        }
        if nextIf("l") {
            let discriminator = popNode(.Identifier)
            return createWithChild(.PrivateDeclName, discriminator)
        }
        if (peekChar() >= "a" && peekChar() <= "j") || (peekChar() >= "A" && peekChar() <= "J") {
            let relatedEntityKind = nextChar()
            let kindNd = createNode(.Identifier, relatedEntityKind)
            let name = popNode()
            let result = createNode(.RelatedEntityDeclName)
            addChild(result, kindNd)
            return addChild(result, name)
        }
        let discriminator = demangleIndexAsNode()
        let name = popNode(isDeclName)
        return createWithChildren(.LocalDeclName, discriminator, name)
    }
    
    func demangleBuiltinType() -> Node? {
        var Ty: Node?
        let maxTypeSize = 4096 // a very conservative upper bound
        switch nextChar() {
        case "b":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_BRIDGEOBJECT)
        case "B":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_UNSAFEVALUEBUFFER)
        case "e":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_EXECUTOR)
        case "f":
            let size = demangleIndex() - 1
            if size <= 0 || size > maxTypeSize {
                return nil
            }
            var name = ""
            name.append(.BUILTIN_TYPE_NAME_FLOAT)
            name.append(size.description)
            Ty = createNode(.BuiltinTypeName, name)
        case "i":
            let size = demangleIndex() - 1
            if size <= 0 || size > maxTypeSize {
                return nil
            }
            var name = ""
            name.append(.BUILTIN_TYPE_NAME_INT)
            name.append(size.description)
            Ty = createNode(.BuiltinTypeName, name)
        case "I":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_INTLITERAL)
        case "v":
            let elts = demangleIndex() - 1
            if elts <= 0 || elts > maxTypeSize {
                return nil
            }
            let EltType = popTypeAndGetChild()
            if !EltType || EltType.getKind() != .BuiltinTypeName || !EltType.getText().hasPrefix(.BUILTIN_TYPE_NAME_PREFIX) {
                return nil
            }
            var name = ""
            name.append(.BUILTIN_TYPE_NAME_VEC)
            name.append(elts.description)
            name.push_back("x")
            name.append(EltType.getText().substr(String.BUILTIN_TYPE_NAME_PREFIX.size()))
            Ty = createNode(.BuiltinTypeName, name)
        case "V":
            guard let element = popNode(.Type) else {
                return nil
            }
            guard let size = popNode(.Type) else {
                return nil
            }
            Ty = createNode(.BuiltinFixedArray)
            addChild(Ty, size)
            addChild(Ty, element)
        case "W":
            guard let referent = popNode(.Type) else {
                return nil
            }
            Ty = createNode(.BuiltinBorrow)
            addChild(Ty, referent)
        case "O":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_UNKNOWNOBJECT)
        case "o":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_NATIVEOBJECT)
        case "p":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_RAWPOINTER)
        case "j":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_JOB)
        case "D":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_DEFAULTACTORSTORAGE)
        case "c":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_RAWUNSAFECONTINUATION)
        case "t":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_SILTOKEN)
        case "w":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_WORD)
        case "P":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_PACKINDEX)
        case "T":
            Ty = createNode(.BuiltinTupleType)
        case "A":
            Ty = createNode(.BuiltinTypeName, .BUILTIN_TYPE_NAME_IMPLICITACTOR)
        default:
            return nil
        }
        return createType(Ty)
    }
}
