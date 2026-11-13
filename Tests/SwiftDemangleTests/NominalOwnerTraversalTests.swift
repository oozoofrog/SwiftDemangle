import Testing
@testable import SwiftDemangle

@MainActor
final class NominalOwnerTraversalTests {
    @Test(arguments: [
        Node.Kind.FunctionType,
        .Tuple,
        .TypeList,
        .ProtocolConformance,
        .ProtocolWitness,
        .VTableThunk,
        .ReabstractionThunkHelper,
        .OpaqueReturnTypeOf,
        .AutoDiffFunction,
        .UnknownIndex,
    ])
    func unsupportedShapesDoNotFollowArbitraryChildren(kind: Node.Kind) {
        let wrapper = Node(kind: kind, children: .sample())
        #expect(wrapper.extractNominalOwner() == nil)
    }

    @Test(arguments: [
        Node.Kind.Global,
        .Type,
        .TypeMangling,
        .Extension,
        .AnonymousContext,
        .Function,
        .Getter,
        .BoundGenericClass,
        .PartialApplyForwarder,
    ])
    func missingChildrenHaveNoOwner(kind: Node.Kind) {
        #expect(Node(kind: kind).extractNominalOwner() == nil)
    }

    @Test(arguments: [
        Node.Kind.GenericSpecialization,
        .DefaultOverride,
        .HasSymbolQuery,
        .AsyncAwaitResumePartialFunction,
    ])
    func functionAttributesDoNotSupplyOwners(kind: Node.Kind) {
        let owner = Node.sample()
        let attribute = Node(kind: kind, children: .sample("AttributePayload"))
        let function = Node(kind: .Function, children: owner)
        let global = Node(kind: .Global, children: attribute, function)
        #expect(global.extractNominalOwner() === owner)
        #expect(Node(kind: .Global, child: attribute).extractNominalOwner() == nil)
        #expect(attribute.extractNominalOwner() == nil)
    }

    @Test
    func anonymousContextFollowsItsParentRatherThanCapturedTypes() {
        let owner = Node.sample()
        let context = Node(
            kind: .AnonymousContext,
            children: Node(kind: .Identifier, text: "anonymous"),
            owner,
            Node(kind: .TypeList, children: .sample("CapturedType"))
        )
        #expect(context.extractNominalOwner() === owner)
    }

    @Test
    func typeManglingSkipsFunctionLabels() {
        let owner = Node.sample()
        let mangling = Node(
            kind: .TypeMangling,
            children: Node(kind: .LabelList),
            Node(kind: .Type, child: owner)
        )
        #expect(mangling.extractNominalOwner() === owner)
    }

    @Test
    func multipleSymbolCandidatesAreAmbiguous() {
        let global = Node(kind: .Global, children: .sample("First"), .sample("Second"))
        #expect(global.extractNominalOwner() == nil)

        let forwarder = Node(
            kind: .PartialApplyForwarder,
            children: .sample("First"), .sample("Second")
        )
        #expect(forwarder.extractNominalOwner() == nil)
    }

    @Test(arguments: [Node.Kind.TypeSymbolicReference, .ProtocolSymbolicReference])
    func unresolvedReferencesHaveNoOwner(kind: Node.Kind) {
        #expect(Node(kind: kind, index: 0).extractNominalOwner() == nil)
    }
}

private extension Node {
    static func sample(_ name: String = "Owner") -> Node {
        Node(
            kind: .Class,
            children: Node(kind: .Module, text: "Module"),
            Node(kind: .Identifier, text: name)
        )
    }
}
