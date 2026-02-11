//
//  Mangling.swift
//  Demangling
//
//  Created by spacefrog on 2021/06/06.
//

import Foundation

protocol Mangling {
    var maxRepeatCount: Int { get }
    
    func isOldFunctionType<S>(_ name: S) -> Bool where S: StringProtocol
    func manglingPrefixLength<S>(from mangled: S) -> Int where S: StringProtocol
}

extension Mangling {
    var maxRepeatCount: Int { 2048 }
    
    func isOldFunctionType<S>(_ name: S) -> Bool where S: StringProtocol {
        name.hasPrefix("_T")
    }
    
    func manglingPrefixLength<S>(from mangled: S) -> Int where S: StringProtocol {
        if mangled.isEmpty {
            return 0
        } else {
            let prefixes = [
                "_T0",              // Swift 4
                "$S", "_$S",        // Swift 4.*
                "$s", "_$s",        // Swift 5+.*
                "$e", "_$e",        // Embedded Swift
                "@__swiftmacro_"    // Swift 5+ for filenames
            ]
            for prefix in prefixes where mangled.hasPrefix(prefix){
                return prefix.count
            }
            return 0
        }
    }
}
