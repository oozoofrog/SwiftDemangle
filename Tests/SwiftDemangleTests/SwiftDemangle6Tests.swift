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
     $sSvSgA3ASbIetCyyd_SgSbIetCyyyd_SgD ---> (@escaping @convention(thin) @convention(c) (@unowned Swift.UnsafeMutableRawPointer?, @unowned Swift.UnsafeMutableRawPointer?, @unowned (@escaping @convention(thin) @convention(c) (@unowned Swift.UnsafeMutableRawPointer?, @unowned Swift.UnsafeMutableRawPointer?) -> (@unowned Swift.Bool))?) -> (@unowned Swift.Bool))?
     */
    @Test
    func tupleEscapingUnowned() {
        let mangled = "$sSvSgA3ASbIetCyyd_SgSbIetCyyyd_SgD"
        let demangled = "(@escaping @convention(thin) @convention(c) (@unowned Swift.UnsafeMutableRawPointer?, @unowned Swift.UnsafeMutableRawPointer?, @unowned (@escaping @convention(thin) @convention(c) (@unowned Swift.UnsafeMutableRawPointer?, @unowned Swift.UnsafeMutableRawPointer?) -> (@unowned Swift.Bool))?) -> (@unowned Swift.Bool))?"
        #expect(mangled.demangled == demangled)
    }
}
    
