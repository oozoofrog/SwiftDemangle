//
//  SwiftDemangle591Tests.swift
//  
//
//  Created by oozoofrg on 12/10/23.
//

import XCTest
@testable import SwiftDemangle

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

    func test$sSUss17FixedWidthIntegerRzrlEyxqd__cSzRd__lufCSu_SiTgm5() throws {
        let mangled = "$sSUss17FixedWidthIntegerRzrlEyxqd__cSzRd__lufCSu_SiTgm5"
        let demangled = "generic specialization <Swift.UInt, Swift.Int> of (extension in Swift):Swift.UnsignedInteger< where A: Swift.FixedWidthInteger>.init<A where A1: Swift.BinaryInteger>(A1) -> A"
        XCTAssertEqual(mangled.demangled, demangled)
    }

    func test$s6Foobar7Vector2VAASdRszlE10simdMatrix5scale6rotate9translateSo0C10_double3x3aACySdG_SdAJtFZ0D4TypeL_aySd__GD() throws {
        let mangled = "$s6Foobar7Vector2VAASdRszlE10simdMatrix5scale6rotate9translateSo0C10_double3x3aACySdG_SdAJtFZ0D4TypeL_aySd__GD"
        let demangled = "MatrixType #1 in static (extension in Foobar):Foobar.Vector2<Swift.Double><A where A == Swift.Double>.simdMatrix(scale: Foobar.Vector2<Swift.Double>, rotate: Swift.Double, translate: Foobar.Vector2<Swift.Double>) -> __C.simd_double3x3"
        XCTAssertEqual(mangled.demangled, demangled)
    }

    func test$s17distributed_thunk2DAC1fyyFTE() throws {
        let mangled = "$s17distributed_thunk2DAC1fyyFTE"
        let demangled = "distributed thunk distributed_thunk.DA.f() -> ()"
        XCTAssertEqual(mangled.demangled, demangled)
    }

    func test$s27distributed_actor_accessors7MyActorC7simple2ySSSiFTETFHF() throws {
        let mangled = "$s27distributed_actor_accessors7MyActorC7simple2ySSSiFTETFHF"
        let demangled = "accessible function runtime record for distributed accessor for distributed thunk distributed_actor_accessors.MyActor.simple2(Swift.Int) -> Swift.String"
        XCTAssertEqual(mangled.demangled, demangled)
    }

    func test$s1A3bar1aySSYt_tF() throws {
        let mangled = "$s1A3bar1aySSYt_tF"
        let demangled = "A.bar(a: _const Swift.String) -> ()"
        XCTAssertEqual(try mangled.demangling(.defaultOptions, printDebugInformation: true), demangled)
    }

    func test$s1t1fyyFSiAA3StrVcs7KeyPathCyADSiGcfu_SiADcfu0_33_556644b740b1b333fecb81e55a7cce98ADSiTf3npk_n() throws {
        let mangled = "$s1t1fyyFSiAA3StrVcs7KeyPathCyADSiGcfu_SiADcfu0_33_556644b740b1b333fecb81e55a7cce98ADSiTf3npk_n"
        let demangled = "function signature specialization <Arg[1] = [Constant Propagated KeyPath : _556644b740b1b333fecb81e55a7cce98<t.Str,Swift.Int>]> of implicit closure #2 (t.Str) -> Swift.Int in implicit closure #1 (Swift.KeyPath<t.Str, Swift.Int>) -> (t.Str) -> Swift.Int in t.f() -> ()"
        // $s1t1fyyFSiAA3StrVcs7KeyPathCyADSiGcfu_SiADcfu0_33_556644b740b1b333fecb81e55a7cce98ADSiTf3npk_n
        XCTAssertEqual(try mangled.demangling(.defaultOptions, printDebugInformation: true), demangled)
    }
    
    func test$s21back_deploy_attribute0A12DeployedFuncyyFTwb() throws {
        let mangled = "$s21back_deploy_attribute0A12DeployedFuncyyFTwb"
        let demangled = "back deployment thunk for back_deploy_attribute.backDeployedFunc() -> ()"
        // $s21back_deploy_attribute0A12DeployedFuncyyFTwb
        XCTAssertEqual(try mangled.demangling(.defaultOptions, printDebugInformation: true), demangled)
    }

    func test$sxIeghHr_xs5Error_pIegHrzo_s8SendableRzs5NeverORs_r0_lTRTATQ0_() throws {
        let mangled = "$sxIeghHr_xs5Error_pIegHrzo_s8SendableRzs5NeverORs_r0_lTRTATQ0_"
        let demangled = "{T:$sxIeghHr_xs5Error_pIegHrzo_s8SendableRzs5NeverORs_r0_lTR} (1) await resume partial function for partial apply forwarder for reabstraction thunk helper <A, B where A: Swift.Sendable, B == Swift.Never> from @escaping @callee_guaranteed @Sendable @async () -> (@out A) to @escaping @callee_guaranteed @async () -> (@out A, @error @owned Swift.Error)"
        var opts: DemangleOptions = .defaultOptions
        opts.isClassify = true
        let result = try mangled.demangling(opts, printDebugInformation: true)
        // (1) await resume partial function for partial apply forwarder for reabstraction thunk helper <A, B where A: Swift.Sendable, B == Swift.Never> from @escaping @callee_guaranteed @Sendable @async () -> (@out A) to @escaping @callee_guaranteed @async () -> (@out A, @error @owned Swift.Error)
        XCTAssertEqual(result, demangled)
    }

    func test$s14swift_ide_test14myColorLiteral3red5green4blue5alphaAA0E0VSf_S3ftcfm() throws {
        let mangled = "$s14swift_ide_test14myColorLiteral3red5green4blue5alphaAA0E0VSf_S3ftcfm"
        let demangled = "swift_ide_test.myColorLiteral(red: Swift.Float, green: Swift.Float, blue: Swift.Float, alpha: Swift.Float) -> swift_ide_test.Color"
        let result = try mangled.demangling(.defaultOptions, printDebugInformation: true)
        // $s14swift_ide_test14myColorLiteral3red5green4blue5alphaAA0E0VSf_S3ftcfm
        XCTAssertEqual(result, demangled)
    }

    func test$s4main4FlagVHa() throws {
        let mangled = "$s4main4FlagVHa"
        let demangled = "runtime discoverable attribute record for main.Flag"
        let result = try mangled.demangling(.defaultOptions, printDebugInformation: true)
        // $s4main4FlagVHa
        XCTAssertEqual(result, demangled)
    }

    func test$s9MacroUser13testStringify1a1bySi_SitF9stringifyfMf1_() throws {
        let mangled = "$s9MacroUser13testStringify1a1bySi_SitF9stringifyfMf1_"
        let demangled = "freestanding macro expansion #3 of stringify in MacroUser.testStringify(a: Swift.Int, b: Swift.Int) -> ()"
        let result = try mangled.demangling(.defaultOptions, printDebugInformation: true)
        XCTAssertEqual(result, demangled)
    }

    // test@__swiftmacro_1a13testStringifyAA1bySi_SitF9stringifyfMf_
    func test__swiftmacro_1a13testStringifyAA1bySi_SitF9stringifyfMf_() throws {
        let mangled = "@__swiftmacro_1a13testStringifyAA1bySi_SitF9stringifyfMf_"
        let demangled = "freestanding macro expansion #1 of stringify in a.testStringify(a: Swift.Int, b: Swift.Int) -> ()"
        let result = try mangled.demangling(.defaultOptions, printDebugInformation: true)
        // {N} @__swiftmacro_1a13testStringifyAA1bySi_SitF9stringifyfMf_
        XCTAssertEqual(result, demangled)
    }

    func test_$s4main1fSiyYaFTQ0_() throws {
        let mangled = "_$s4main1fSiyYaFTQ0_"
        let demangled = "f()"
        let result = try mangled.demangling(.simplifiedOptions, printDebugInformation: true)
        // (1) await resume partial function for f()
        XCTAssertEqual(result, demangled)
    }
}
