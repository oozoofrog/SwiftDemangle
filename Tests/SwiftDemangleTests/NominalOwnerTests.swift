import SwiftDemangle
import Testing

@MainActor
final class NominalOwnerTests {
    @Test(arguments: [
        ("$s6Widget7ManagerC", Node.Kind.Class, ["Widget", "Manager"]),
        ("$s6Widget6RecordV", .Structure, ["Widget", "Record"]),
        ("$s6Widget5StateO", .Enum, ["Widget", "State"]),
        ("$s7SwiftUI4ViewP", .Protocol, ["SwiftUI", "View"]),
        ("$s6Widget6OpaqueXY", .OtherNominalType, ["Widget", "Opaque"]),
        ("$s6Widget7ManagerC6NestedV", .Structure, ["", "Nested"]),
        ("$s6Widget5OuterV5InnerO3runyyF", .Enum, ["", "Inner"]),
        ("$s6Widget7GenericVySiG", .Structure, ["Widget", "Generic"]),
        ("$s6Widget7GenericCySiG", .Class, ["Widget", "Generic"]),
        ("$s6Widget7GenericOySiG", .Enum, ["Widget", "Generic"]),
        ("$s6Widget7ManagerCD", .Class, ["Widget", "Manager"]),
        ("$s6Widget7ManagerCMa", .Class, ["Widget", "Manager"]),
        ("$s6Widget7ManagerCMn", .Class, ["Widget", "Manager"]),
        ("_TtCSo8NSObject", .Class, ["__C", "NSObject"]),
        ("_TtGSaSS_", .Structure, ["Swift", "Array"]),
    ])
    func nominalDeclarations(symbol: String, kind: Node.Kind, childTexts: [String]) throws {
        let owner = try #require(symbol.nominalOwner)
        #expect(owner.kind == kind)
        #expect(owner.children.map(\.text) == childTexts)
    }

    @Test(arguments: [
        "$s6Widget7ManagerC9operationyyF",
        "$s6Widget7ManagerC9operationAA7PayloadVyF",
        "$s6Widget7ManagerC9operationyyAA7PayloadVF",
        "$s6Widget7ManagerC5valueSivp",
        "$s6Widget7ManagerC5valueSivg",
        "$s6Widget7ManagerC5valueSivs",
        "$s6Widget7ManagerC4itemAA7PayloadVvgZ",
        "$s6Widget7ManagerCyS2icig",
        "$s6Widget7ManagerCACycfc",
        "$s6Widget7ManagerCACycfC",
        "$s6Widget7ManagerCfd",
        "$s6Widget7ManagerCfD",
        "$s6Widget7ManagerCfZ",
        "$s6Widget7ManagerC9operationyyFyycfU_",
        "$s6Widget7ManagerC9operationyyFyycfu_",
        "$s6Widget7ManagerC9operationyyFfA_",
        "$s6Widget7ManagerC5valueSivpfi",
        "$s6Widget7ManagerC5AliasaySiGD",
        "$s6Widget7ManagerC6ExtrasE9operationyyF",
        "$s6Widget7ManagerC9operationyyFTo",
        "$s6Widget7ManagerC9operationyyFSi_Tg5",
        "$s6Widget7ManagerC9operationyyFTwB",
        "$s6Widget7ManagerC9operationyyFTY0_",
        "$s6Widget7ManagerC9operationyyFTA",
        "$s6Widget7ManagerC9operationyyFTa",
        "$s6Widget7ManagerC9operationyyFTaTA",
        "$s6Widget7ManagerC9operationyyFToTATQ0_",
        "$s6Widget7ManagerC9operationyyFTwBTa",
        "$s6Widget7ManagerC9operationyyFTA.1",
        "$s6Widget7ManagerC9operationyyFTj",
        "$s6Widget7ManagerC9operationyyFTq",
        "$s6Widget7ManagerC5valueSivpMV",
    ])
    func memberOwners(symbol: String) throws {
        let owner = try #require(symbol.nominalOwner)
        #expect(owner.kind == .Class)
        #expect(owner.children.map(\.kind) == [.Module, .Identifier])
        #expect(owner.children.map(\.text) == ["Widget", "Manager"])
    }

    @Test(arguments: [
        ("_TFE11ext_structAV11def_structA1A4testfT_T_", Node.Kind.Structure, ["def_structA", "A"]),
        (
            "_TFe27mangling_generic_extensionsRxS_8RunciblerVS_3Foog1aSi", .Structure,
            ["mangling_generic_extensions", "Foo"]
        ),
        ("_$Ss10DictionaryV3t17E6Index2V1loiySbAEyxq__G_AGtFZ", .Structure, ["", "Index2"]),
        ("$sSUss17FixedWidthIntegerRzrlEyxqd__cSzRd__lufCSu_SiTg5", .Protocol, ["Swift", "UnsignedInteger"]),
        ("_TFC3foo3bar3basfT3zimCS_3zim_T_", .Class, ["foo", "bar"]),
        ("_$s6Widget0A12KitExtensionVACycfc", .Structure, ["Widget", "WidgetKitExtension"]),
    ])
    func legacyAndGenericContexts(symbol: String, kind: Node.Kind, childTexts: [String]) throws {
        let owner = try #require(symbol.nominalOwner)
        #expect(owner.kind == kind)
        #expect(owner.children.map(\.text) == childTexts)
    }

    @Test(arguments: [
        "$s6Widget9operationyyF",
        "$s6Widget9operationAA7PayloadVyF",
        "$s6Widget9operationyyAA7PayloadVF",
        "$s6Widget4itemAA7PayloadVvg",
        "$s6Widget5AliasaySiGD",
        "$s6Widget9operationyyFyycfU_",
        "$s6Widget",
        "$sSi_SSt",
        "$sS2ic",
        "$sS2icD",
        "_$sTA.123",
        "_T013call_protocol1CCAA1PA2aDP3fooSiyFTW",
        "$s4null16NonSendableKlassCIegHo_ACs5Error_pIegHTrzo_TR",
    ])
    func noOwnerIsInferredFromReferencedTypes(symbol: String) throws {
        // Require successful parsing so a malformed fixture cannot hide a regression.
        _ = try #require(symbol.node)
        #expect(symbol.nominalOwner == nil)
    }

    @Test(arguments: ["", "hello", "__mh_execute_header", "$s", "$s7Widget"])
    func invalidSymbolsHaveNoOwner(symbol: String) {
        #expect(symbol.node == nil)
        #expect(symbol.nominalOwner == nil)
    }
}
