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
}
