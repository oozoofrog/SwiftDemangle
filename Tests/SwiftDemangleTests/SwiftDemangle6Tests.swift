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
}
    
