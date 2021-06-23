//
//  String+Extension.swift
//  Demangling
//
//  Created by spacefrog on 2021/04/02.
//

import Foundation

public extension String {
    
    public var demangled: String {
        return self.demangling(.defaultOptions)
    }
    
    public func demangling(_ options: DemangleOptions) -> String {
        guard let regex = try? NSRegularExpression(pattern: "[^ \n\r\t]+", options: []) else { return self }
        return regex.matches(in: self, options: [], range: NSRange(startIndex..<endIndex, in: self)).reversed().reduce(self, { (text, match) -> String in
            if let range = Range<String.Index>.init(match.range, in: text) {
                let demangled = text[range].demangleSymbolAsString(with: options)
                return text.replacingCharacters(in: range, with: demangled)
            } else {
                return text
            }
        })
    }
}


extension String {
    func lowercasedOnlyFirst() -> String {
        var string = self
        return string.removeFirst().lowercased() + string
    }
    
    var character: Character { self.first ?? .zero }
}

public protocol StringIntegerIndexable: StringProtocol {
    subscript(_ indexRange: Range<Int>) -> Substring { get }
    subscript(r: Range<Self.Index>) -> Substring { get }
}

extension StringIntegerIndexable {
    public subscript(_ index: Int) -> Character {
        self[self.index(self.startIndex, offsetBy: index)]
    }
    public subscript(_ indexRange: Range<Int>) -> Substring {
        guard indexRange.lowerBound >= 0, indexRange.upperBound <= self.count else { return "" }
        let range = Range<Self.Index>(uncheckedBounds: (self.index(self.startIndex, offsetBy: indexRange.lowerBound), self.index(self.startIndex, offsetBy: indexRange.upperBound)))
        return self[range]
    }
}

extension String: StringIntegerIndexable {}
extension Substring: StringIntegerIndexable {}
