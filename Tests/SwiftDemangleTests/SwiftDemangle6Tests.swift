//
//  File.swift
//  SwiftDemangle
//
//  Created by oozoofrog on 11/23/24.
//

import Foundation
import Testing

struct SwiftDemangle6Tests {
    /**
     $sxSo8_NSRangeVRlzCRl_Cr0_llySo12ModelRequestCyxq_GIsPetWAlYl_TC ---> coroutine continuation prototype for @escaping @convention(thin) @convention(witness_method) @yield_once <A, B where A: AnyObject, B: AnyObject> @substituted <A> (@inout A) -> (@yields @inout __C._NSRange) for <__C.ModelRequest<A, B>>
     */
    @MainActor
    @Test
    func coroutineContinuationPrototype() {
        let mangled = "$sxSo8_NSRangeVRlzCRl_Cr0_llySo12ModelRequestCyxq_GIsPetWAlYl_TC"
        let demangled = "coroutine continuation prototype for @escaping @convention(thin) @convention(witness_method) @yield_once <A, B where A: AnyObject, B: AnyObject> @substituted <A> (@inout A) -> (@yields @inout __C._NSRange) for <__C.ModelRequest<A, B>>"
        #expect(mangled.demangled == demangled)
    }
}
    
