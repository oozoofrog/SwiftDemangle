import SwiftDemangle
import Testing

@MainActor
final class NodeTraversalTests {
    @Test
    func readOnlyTraversal() throws {
        let root = try #require("$s6Widget7ManagerC9operationyyF".node)
        #expect(root.kind == .Global)
        #expect(root.text.isEmpty)
        #expect(root.index == nil)
        #expect(root.children.map(\.kind) == [.Function])

        let function = try #require(root.children.first)
        #expect(function.children.map(\.kind) == [.Class, .Identifier, .Type])
        #expect(function.children.map(\.text) == ["", "operation", ""])

        let owner = try #require(function.children.first)
        #expect(owner.kind == .Class)
        #expect(owner.children.map(\.kind) == [.Module, .Identifier])
        #expect(owner.children.map(\.text) == ["Widget", "Manager"])

        var children = root.children
        children.removeAll()
        #expect(children.map(ObjectIdentifier.init) == [])
        #expect(root.children.map(ObjectIdentifier.init) == [ObjectIdentifier(function)])
    }

    @Test
    func numericPayload() throws {
        let root = try #require("$s6Widget7ManagerC9operationyyFyycfU_".node)
        #expect(root.children.map(\.kind) == [.ExplicitClosure])

        let closure = try #require(root.children.first)
        #expect(closure.children.map(\.kind) == [.Function, .Number, .Type])
        #expect(closure.children.map(\.index) == [nil, 0, nil])
        #expect(closure.children.map(\.text) == ["", "", ""])
    }
}
