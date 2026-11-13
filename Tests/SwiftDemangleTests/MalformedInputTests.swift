import Foundation
import SwiftDemangle
import Testing

@MainActor
final class MalformedInputTests {
    /// Truncated or overflowing input must come back unchanged, without trapping or hanging.
    @Test(.timeLimit(.minutes(1)), arguments: [
        // Specialization that ends inside a constant propagation chain.
        "$s4main3fooyyFTf4p",
        "$s4main3fooyyFTf4pp",
        "$s4main3fooyyFTf4npi3p",
        "$s4main3fooyyFTf4pf",
        "$s4main3fooyyFTf4pi3",
        "$s4main3fooyyFTf4pk",
        // Natural numbers that do not fit in 32 bits.
        "$s4main3fooyyFTf4C99999999999999999999_n",
        "$s4main3fooyyFTf4C2147483648_n",
        "$s99999999999999999999",
        // Associated type witness table accessor without an associated type path.
        "$s4main1SVAA1PAAxAA1QPWT",
    ])
    func malformedInputIsReturnedUnchanged(symbol: String) {
        #expect(symbol.demangled == symbol)
    }

    /// Inputs that used to trap. Only termination is checked here.
    @Test(.timeLimit(.minutes(1)), arguments: [
        // Identifier length longer than the remaining input.
        "_TF3",
        "_Tv3",
        "_TtC3",
        "log: _TF3 crashed",
        // Substitution index at UInt64.max.
        "_TtS18446744073709551615_",
        "_TtCS18446744073709551615_",
        // Reabstraction thunks without their type children.
        "$sTR",
        "$sTy",
        "sTR",
        "$s4mini3SeqPAA06BorrowB0Ty",
        // Punycode code point above UInt32.max.
        "$s0059xxxxxxxxxxxxxxx_ttttttttBBBBBBBBBBBBBBBBcBBBBBBBBBBBBBBBBee",
    ])
    func malformedInputDoesNotTrap(symbol: String) {
        _ = symbol.demangled
    }

    /// Every proper prefix of every symbol in manglings.txt must demangle without trapping.
    @Test(.timeLimit(.minutes(1)))
    func truncatedSymbolsDoNotTrap() throws {
        let path = try #require(Bundle.module.path(forResource: "manglings.txt", ofType: ""))
        let lines = try String(contentsOfFile: path, encoding: .utf8).split(separator: "\n")
        var count = 0
        for line in lines {
            guard let arrow = line.range(of: " ---> ") else { continue }
            let mangled = line[..<arrow.lowerBound].trimmingCharacters(in: .whitespaces)
            for end in mangled.indices.dropFirst() {
                _ = String(mangled[..<end]).demangled
                count += 1
            }
        }
        #expect(count > 10_000)
    }

    /// Nesting beyond the depth limit is returned unchanged, even on a 512 KB stack.
    @Test(.timeLimit(.minutes(1)), arguments: ["Sg x 500", "Sg x 10000", "GSq x 20000"])
    func deeplyNestedSymbolIsReturnedUnchanged(shape: String) async {
        let symbol = switch shape {
        case "Sg x 500": "$sSi" + String(repeating: "Sg", count: 500) + "D"
        case "Sg x 10000": "$sSi" + String(repeating: "Sg", count: 10_000) + "D"
        default: "_Tt" + String(repeating: "GSq", count: 20_000) + "Si" + String(repeating: "_", count: 20_000)
        }
        let result = await withCheckedContinuation { continuation in
            let thread = Thread {
                continuation.resume(returning: symbol.demangled)
            }
            thread.stackSize = 512 * 1024
            thread.start()
        }
        #expect(result == symbol)
    }
}
