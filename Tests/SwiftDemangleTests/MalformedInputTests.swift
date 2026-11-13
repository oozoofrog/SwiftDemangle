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
        // Old protocol descriptor without a protocol name.
        "_TMp",
        "_TMps10Comparabl",
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
        // Found by mutating the resource-file symbols.
        // Old variadic tuple without elements.
        "_Ttt_",
        // Old differentiable function type with an unknown kind.
        "_TtbDiSu",
        "_TFC3foo3barcfD_S0_",
        // Function type kind the printer does not handle.
        "$S3abc6testityySiDTm",
        "_$S8mangling14varargsVsArray3arr1nySid_SStD",
        // Impl function type with more than one substitution list.
        "$s39differentiation_subset_parameters_thunk19inoutIndirectCalleryq_x_q_q0_t16_Differentiation14DifferentiableRzAcDR_AcDR0_r1_lFxq_Sdq_xq_Sdr0_ly13TangentVectorAcDPly_AeFQzIsegnrr_Iegnnnro_TJSrSSSpSrSUSP",
        // Clang type followed by more input.
        "$sxxxIxzC1xxxesy",
        // Key path index operator and value generic marker of mutated symbols.
        "_T0Ix_IyB_TH",
        "_T010Foundation11MeasurementV12SimulatorKitSo9UnitAngleCRVzlE11OrientationO2eeoiSbAcDEAGOyAF_G_AKtFZ",
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
    @Test(.timeLimit(.minutes(1)), arguments: [
        "Sg x 500", "Sg x 10000", "GSq x 20000",
        // Shapes whose nodes gain children after they are attached to their parent.
        "impl function x 600", "protocol list x 3000", "specialization x 3000",
    ])
    func deeplyNestedSymbolIsReturnedUnchanged(shape: String) async {
        let symbol = switch shape {
        case "Sg x 500": "$sSi" + String(repeating: "Sg", count: 500) + "D"
        case "Sg x 10000": "$sSi" + String(repeating: "Sg", count: 10_000) + "D"
        case "impl function x 600": "$sSi" + String(repeating: "Iyx_", count: 600)
        case "protocol list x 3000":
            "$s" + String(repeating: "4main3fooyy", count: 3000) + "Si" + String(repeating: "F1PL_P_p", count: 3000)
        case "specialization x 3000":
            "$s" + String(repeating: "s3foo", count: 3000) + "Si" + String(repeating: "Tf1c_nLaV", count: 3000)
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
    /// A constant-propagated function is itself a symbol; a chain of them must not recurse without bound.
    @Test(.timeLimit(.minutes(1)))
    func symbolsNestedInConstantPropagationTerminate() {
        var symbol = "$s4main3fooyyF"
        var twoLevels = ""
        for level in 1...400 {
            symbol = "$s\(symbol.count)\(symbol)Tf1pf_n"
            if level == 2 { twoLevels = symbol }
        }
        #expect(twoLevels.demangled.contains("main.foo() -> ()"))
        #expect(symbol.demangled != symbol)
    }
}
