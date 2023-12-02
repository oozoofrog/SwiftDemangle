//
//  SwiftDemangle591Tests.swift
//  
//
//  Created by oozoofrg on 12/10/23.
//

import XCTest
import SwiftDemangle

final class SwiftDemangle591Tests: XCTestCase {

    func test591() throws {
        var mangled = "_TtBv4Bf16_"
        var demangled = "Builtin.Vec4xFPIEEE16"
        XCTAssertEqual(mangled.demangled, demangled)

        mangled = "_T03nix6testitSaySiGyFTv_r"
        demangled = "outlined read-only object #0 of nix.testit() -> [Swift.Int]"
        XCTAssertEqual(mangled.demangled, demangled)

        mangled = "$ss6SimpleHr"
        demangled = "protocol descriptor runtime record for Swift.Simple"
        XCTAssertEqual(mangled.demangled, demangled)

        mangled = "$ss5OtherVs6SimplesHc"
        demangled = "protocol conformance descriptor runtime record for Swift.Other : Swift.Simple in Swift"
        XCTAssertEqual(mangled.demangled, demangled)

        mangled = "$ss5OtherVHn"
        demangled = "nominal type descriptor runtime record for Swift.Other"
        XCTAssertEqual(mangled.demangled, demangled)

        mangled = "$s18opaque_return_type3fooQryFQOHo"
        demangled = "opaque type descriptor runtime record for <<opaque return type of opaque_return_type.foo() -> some>>"
        XCTAssertEqual(mangled.demangled, demangled)
    }

    func test591_2() throws {
        let mangled = "$sSUss17FixedWidthIntegerRzrlEyxqd__cSzRd__lufCSu_SiTgm5"
        let demangled = "generic specialization <Swift.UInt, Swift.Int> of (extension in Swift):Swift.UnsignedInteger< where A: Swift.FixedWidthInteger>.init<A where A1: Swift.BinaryInteger>(A1) -> A"
        XCTAssertEqual(mangled.demangled, demangled)
    }

    func test591_3() throws {
        let mangled = "$s6Foobar7Vector2VAASdRszlE10simdMatrix5scale6rotate9translateSo0C10_double3x3aACySdG_SdAJtFZ0D4TypeL_aySd__GD"
        let demangled = "MatrixType #1 in static (extension in Foobar):Foobar.Vector2<Swift.Double><A where A == Swift.Double>.simdMatrix(scale: Foobar.Vector2<Swift.Double>, rotate: Swift.Double, translate: Foobar.Vector2<Swift.Double>) -> __C.simd_double3x3"
        XCTAssertEqual(mangled.demangled, demangled)
    }
}
