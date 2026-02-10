import Testing
@testable import SwiftDemangle

@MainActor
final class SymbolKindTests {
    @Test
    func testConstructorKind() {
        let mangled = "_$s6Widget0A12KitExtensionVACycfc"
        #expect(mangled.symbolKind == .Constructor)
    }

    @Test
    func testFunctionKind() {
        let mangled = "$s6Widget9operationyyF"
        #expect(mangled.symbolKind == .Function)
    }

    @Test
    func testGlobalUnwrapping() {
        // Global symbols should unwrap to inner kind
        let mangled = "$sSo18NSNotificationNameaSYSCSY8rawValuexSg03RawD0Qz_tcfCTWTm"
        #expect(mangled.symbolKind != nil)
        #expect(mangled.symbolKind != .Global)
    }

    @Test
    func testNonSwiftSymbol() {
        let mangled = "__mh_execute_header"
        #expect(mangled.symbolKind == nil)
    }

    @Test
    func testClassKind() {
        let mangled = "$s6Widget7ManagerC"
        #expect(mangled.symbolKind == .Class)
    }

    @Test
    func testProtocolKind() {
        let mangled = "$s7SwiftUI4ViewP"
        #expect(mangled.symbolKind == .Protocol)
    }
}
