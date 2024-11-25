//
//  File.swift
//  SwiftDemangle
//
//  Created by oozoofrog on 11/23/24.
//

import Foundation
import Testing
@testable import SwiftDemangle

@MainActor
struct SwiftDemangle6Tests {
    /**
     $sxSo8_NSRangeVRlzCRl_Cr0_llySo12ModelRequestCyxq_GIsPetWAlYl_TC ---> coroutine continuation prototype for @escaping @convention(thin) @convention(witness_method) @yield_once <A, B where A: AnyObject, B: AnyObject> @substituted <A> (@inout A) -> (@yields @inout __C._NSRange) for <__C.ModelRequest<A, B>>
     */
    @Test
    func coroutineContinuationPrototype() {
        let mangled = "$sxSo8_NSRangeVRlzCRl_Cr0_llySo12ModelRequestCyxq_GIsPetWAlYl_TC"
        let demangled = "coroutine continuation prototype for @escaping @convention(thin) @convention(witness_method) @yield_once <A, B where A: AnyObject, B: AnyObject> @substituted <A> (@inout A) -> (@yields @inout __C._NSRange) for <__C.ModelRequest<A, B>>"
        print("R:" + mangled.demangled)
        print("E:" + demangled)
        #expect(mangled.demangled == demangled)
    }
    
    /**
     $SyyySGSS_IIxxxxx____xsIyFSySIxx_@xIxx____xxI ---> $SyyySGSS_IIxxxxx____xsIyFSySIxx_@xIxx____xxI
     */
    @Test
    func noDemangled() {
        let mangled = "$SyyySGSS_IIxxxxx____xsIyFSySIxx_@xIxx____xxI"
        let demangled = "$SyyySGSS_IIxxxxx____xsIyFSySIxx_@xIxx____xxI"
        #expect(mangled.demangled == demangled)
    }
    
    /**
     _TtbSiSu ---> @convention(block) (Swift.Int) -> Swift.UInt
     */
    @Test
    func testConventionBlock() {
        let mangled = "_TtbSiSu"
        let demangled = "@convention(block) (Swift.Int) -> Swift.UInt"
        #expect(mangled.demangled == demangled)
    }
    
    /**
     $s$n3_SSBV ---> Builtin.FixedArray<-4, Swift.String>
     */
    @Test func testNegativeInteger() async throws {
        let mangled = "$s$n3_SSBV"
        let demangled = "Builtin.FixedArray<-4, Swift.String>"
        #expect(try mangled.demangling(.defaultOptions.classified()) == demangled)
    }
    
    /**
     $s4main3fooyySiFyyXEfU_TA.1 ---> {T:} partial apply forwarder for closure #1 () -> () in main.foo(Swift.Int) -> () with unmangled suffix ".1"
     */
    @Test func testPartialApplyForwarder() async throws {
        let mangled = "$s4main3fooyySiFyyXEfU_TA.1"
        let demangled = "{T:} partial apply forwarder for closure #1 () -> () in main.foo(Swift.Int) -> () with unmangled suffix \".1\""
        #expect(try mangled.demangling(.defaultOptions.classified()) == demangled)
    }
    
    /**
     _TFC3foo3barZ ---> foo.bar.__isolated_deallocating_deinit failed
     */
    @Test func testIsolatedDeallocatingDeinitFailed() async throws {
        let mangled = "_TFC3foo3barZ"
        let demangled = "foo.bar.__isolated_deallocating_deinit"
        print("R:" + mangled.demangled)
        print("E:" + demangled)
        #expect(mangled.demangled == demangled)
    }
    
    /**
     _TFC3red11BaseClassEHcfzT1aSi_S0_ ---> red.BaseClassEH.init(a: Swift.Int) throws -> red.BaseClassEH
     */
    @Test func testBaseClassEH() async throws {
        let mangled = "_TFC3red11BaseClassEHcfzT1aSi_S0_"
        let demangled = "red.BaseClassEH.init(a: Swift.Int) throws -> red.BaseClassEH"
        #expect(mangled.demangled == demangled)
    }
    
    /**
     _T0s17MutableCollectionP1asAARzs012RandomAccessB0RzsAA11SubSequences013BidirectionalB0PRpzsAdHRQlE06rotatecD05Indexs01_A9IndexablePQzAM15shiftingToStart_tFAJs01_J4BasePQzAQcfU_ ---> closure #1 (A.Swift._IndexableBase.Index) -> A.Swift._IndexableBase.Index in (extension in a):Swift.MutableCollection<A where A: Swift.MutableCollection, A: Swift.RandomAccessCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.MutableCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.RandomAccessCollection>.rotateRandomAccess(shiftingToStart: A.Swift._MutableIndexable.Index) -> A.Swift._MutableIndexable.Index
     */
    @Test func demangleMultiSubstitutions() async throws {
        let mangled = "_T0s17MutableCollectionP1asAARzs012RandomAccessB0RzsAA11SubSequences013BidirectionalB0PRpzsAdHRQlE06rotatecD05Indexs01_A9IndexablePQzAM15shiftingToStart_tFAJs01_J4BasePQzAQcfU_"
        let demangled = "closure #1 (A.Swift._IndexableBase.Index) -> A.Swift._IndexableBase.Index in (extension in a):Swift.MutableCollection<A where A: Swift.MutableCollection, A: Swift.RandomAccessCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.MutableCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.RandomAccessCollection>.rotateRandomAccess(shiftingToStart: A.Swift._MutableIndexable.Index) -> A.Swift._MutableIndexable.Index"
        #expect(mangled.demangled == demangled)
    }
    
    /**
     $s4test7genFuncyyx_q_tr0_lFSi_SbTtt1g5 ---> generic specialization <Swift.Int, Swift.Bool> of test.genFunc<A, B>(A, B) -> ()
     */
    @Test func testGenericSpecialization() async throws {
        let mangled = "$s4test7genFuncyyx_q_tr0_lFSi_SbTtt1g5"
        let demangled = "generic specialization <Swift.Int, Swift.Bool> of test.genFunc<A, B>(A, B) -> ()"
        #expect(mangled.demangled == demangled)
    }
}
    
