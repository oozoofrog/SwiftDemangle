//
//  File.swift
//  SwiftDemangle
//
//  Created by oozoofrog on 11/24/24.
//

import Foundation

enum InvertibleProtocols: UInt64 {
    case Copyable = 0
    case Escapable = 1
    
    var name: String {
        switch self {
        case .Copyable:
            return "Copyable"
        case .Escapable:
            return "Escapable"
        }
    }
}
