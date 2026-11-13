//
//  Demanglerable.swift
//  Demangling
//
//  Created by spacefrog on 2021/06/06.
//

import Foundation

/// Reads the mangled input like upstream `Demangler` (`Text` + `Pos`):
/// `buffer` never changes and reading only moves `position` forward.
protocol Demanglerable: AnyObject {
    /// The whole mangled input as ASCII bytes.
    var buffer: [UInt8] { get }
    /// Index of the next unread byte in `buffer`.
    var position: Int { get set }
    var numerics: [Character] { get }
    var substitutions: [Node] { get }

    init(_ mangled: String)
}

extension Demanglerable {

    /// The input as bytes; a string that is not ASCII becomes empty input.
    static func bytes(of mangled: String) -> [UInt8] {
        Array(mangled.data(using: .ascii) ?? Data())
    }

    /// Number of unread bytes.
    var remaining: Int {
        buffer.count - position
    }

    /// The unread text.
    var text: String {
        String(decoding: buffer[position...], as: UTF8.self)
    }

    /// The whole input, including what has been read.
    var textOriginal: String {
        String(decoding: buffer, as: UTF8.self)
    }

    var isEmpty: Bool {
        position >= buffer.count
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    /// The next character, or `.zero` at the end of the input.
    func peekChar() -> Character {
        isEmpty ? .zero : buffer[position].character
    }

    /// Reads one character; returns `.zero` and reads nothing at the end of the input.
    @discardableResult
    func nextChar() -> Character {
        guard isNotEmpty else { return .zero }
        defer { position += 1 }
        return buffer[position].character
    }

    @discardableResult
    func nextIf(_ character: Character) -> Bool {
        guard peekChar() == character else { return false }
        advanceOffset(1)
        return true
    }

    @discardableResult
    func nextIf(_ prefix: String) -> Bool {
        let bytes = prefix.utf8
        guard bytes.count <= remaining, buffer[position..<(position + bytes.count)].elementsEqual(bytes) else { return false }
        position += bytes.count
        return true
    }

    /// Un-reads the last character.
    func pushBack() {
        assert(position > 0)
        position -= 1
    }

    func nextNumber<BI>(_ type: BI.Type) -> BI? where BI: BinaryInteger & BitwiseCopyable {
        let size = MemoryLayout<BI>.size
        guard size <= remaining else { return nil }
        defer { position += size }
        return buffer.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: position, as: BI.self) }
    }

    /// Reads up to `prefixLength` characters. With nothing to read, returns the unread text without reading it.
    func nextString(_ prefixLength: Int) -> String {
        let length = min(prefixLength, remaining)
        guard length > 0 else { return text }
        defer { position += length }
        return slice(length)
    }

    /// The next `length` characters, without reading them.
    func slice(_ length: Int) -> String {
        String(decoding: buffer[position..<(position + min(length, remaining))], as: UTF8.self)
    }

    func advanceOffset(_ length: Int) {
        position += min(length, remaining)
    }

    func hasAtLeast(_ length: UInt64) -> Bool {
        length <= remaining
    }

    func readUntil(_ c: Character) -> String {
        var result: String = ""
        while isNotEmpty, let peeked = peekChar().notEqualOrNil(c) {
            result.append(peeked.description)
            advanceOffset(1)
        }
        return result
    }

    func consumeAll() -> String {
        defer { position = buffer.count }
        return text
    }

    func isStartOfEntity(_ character: Character?) -> Bool {
        switch character {
        case "F", "I", "v", "P", "s", "Z":
            return true
        default:
            return isStartOfNominalType(character)
        }
    }

    func isStartOfIdentifier(_ character: Character) -> Bool {
        numerics.contains(character) || character == "o"
    }

    func isStartOfNominalType(_ character: Character?) -> Bool {
        switch character {
        case "C", "V", "O":
            return true
        default:
            return false
        }
    }

    func nominalTypeMarkerToNodeKind(_ character: Character) -> Node.Kind {
        switch character {
        case "C":
            return .Class
        case "V":
            return .Structure
        case "O":
            return .Enum
        default:
            return .Identifier
        }
    }

}
