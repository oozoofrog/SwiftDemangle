import Foundation
import Testing
@testable import SwiftDemangle

@MainActor
final class NodeHeightTests {
    /// The depth limit reads `Node.height`, so it must equal the real depth of every node.
    @Test(arguments: ["manglings.txt", "simplified-manglings.txt", "manglings-with-clang-types.txt", "experimental-manglings.txt"])
    func storedHeightEqualsRealDepth(resource: String) throws {
        let path = try #require(Bundle.module.path(forResource: resource, ofType: ""))
        var checked = 0
        for line in try String(contentsOfFile: path, encoding: .utf8).split(separator: "\n") {
            guard let arrow = line.range(of: " ---> ") else { continue }
            var mangled = line[..<arrow.lowerBound].trimmingCharacters(in: .whitespaces)
            if mangled.hasPrefix("s") || mangled.hasPrefix("S") { mangled = "$" + mangled }
            guard let root = mangled.node else { continue }
            var depths: [ObjectIdentifier: Int] = [:]
            func depth(_ node: Node) -> Int {
                if let known = depths[ObjectIdentifier(node)] { return known }
                let value = node.children.reduce(0) { max($0, depth($1) + 1) }
                depths[ObjectIdentifier(node)] = value
                if node.height != value {
                    Issue.record("\(mangled): \(node.kind) has height \(node.height), real depth \(value)")
                }
                return value
            }
            _ = depth(root)
            checked += 1
        }
        #expect(checked > 0)
    }
}
