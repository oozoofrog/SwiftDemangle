import XCTest
@testable import SwiftDemangle

final class SwiftDemangleTests: XCTestCase {
    func testPunycode() {
        let punycoded = "Proprostnemluvesky_uybCEdmaEBa"
        let encoded = "Pročprostěnemluvíčesky"
        XCTAssertEqual(Punycode(string: punycoded).decode(), encoded)
    }
    
    func testDemangle() throws {
        let mangled = "$s4test10returnsOptyxycSgxyScMYccSglF"
        let demangled = "test.returnsOpt<A>((@Swift.MainActor () -> A)?) -> (() -> A)?"
        let opts: DemangleOptions = .defaultOptions
        let result = try mangled.demangling(opts)
        XCTAssertEqual(result, demangled, "\n\(mangled) ---> \n\(result)\n\(demangled)")
    }
    
    func testManglings() throws {
        try loadAndForEachMangles("manglings.txt") { line, mangled, demangled in
            var opts: DemangleOptions = .defaultOptions
            var result = try mangled.demangling(opts)
            if result != demangled {
                opts.isClassify = true
                result = try mangled.demangling(opts)
            }
            if result != demangled {
                print("[TEST] demangling for \(line):  \(mangled) failed")
            }
            XCTAssertEqual(result, demangled, "\n\(line): \(mangled) ---> \n\(result)\n\(demangled)")
        }
    }
    
    func testSimplifiedManglings() throws {
        try loadAndForEachMangles("simplified-manglings.txt") { line, mangled, demangled in
            let opts: DemangleOptions = .simplifiedOptions
            let result = try mangled.demangling(opts)
            if result != demangled {
                print("[TEST] simplified demangle for \(line): \(mangled) failed")
            }
            XCTAssertEqual(result, demangled, "\n\(line): \(mangled) ---> \n\(result)\n\(demangled)")
        }
    }
    
    func testManglingsWithClangTypes() throws {
        try loadAndForEachMangles("manglings-with-clang-types.txt") { line, mangled, demangled in
            let opts: DemangleOptions = .simplifiedOptions
            let result = try mangled.demangling(opts)
            if result != demangled {
                print("[TEST] mangled_with_clang_type demangle for \(line): \(mangled) failed")
            }
            XCTAssertEqual(result, demangled, "\n\(line): \(mangled) ---> \n\(result)\n\(demangled)")
        }
    }
    
    func testFunctionSigSpecializationParamKind() throws {
        typealias Kind = FunctionSigSpecializationParamKind
        
        let kindOnly = Kind(rawValue: Kind.Kind.ClosureProp.rawValue)
        XCTAssertEqual(kindOnly.kind, .ClosureProp)
        XCTAssertTrue(kindOnly.optionSet.isEmpty)
        
        let optionSet: Kind.OptionSet = [.Dead, .GuaranteedToOwned]
        let kindAndOptionSet = Kind(rawValue: Kind.Kind.ClosureProp.rawValue | optionSet.rawValue)
        
        XCTAssertNotEqual(kindAndOptionSet.kind, .ClosureProp)
        XCTAssertNotEqual(kindAndOptionSet.kind, .BoxToStack)
        XCTAssertNotEqual(kindAndOptionSet.kind, .BoxToValue)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropFloat)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropFunction)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropGlobal)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropInteger)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropString)
        
        XCTAssertTrue(kindAndOptionSet.containOptions(.Dead))
        XCTAssertTrue(kindAndOptionSet.containOptions(.GuaranteedToOwned))
        XCTAssertFalse(kindAndOptionSet.containOptions(.ExistentialToGeneric))
        XCTAssertFalse(kindAndOptionSet.containOptions(.OwnedToGuaranteed))
        XCTAssertFalse(kindAndOptionSet.containOptions(.SROA))
        
        XCTAssertTrue(kindAndOptionSet.isValidOptionSet)
        
        let extraOptionSet: UInt = 1 << 11
        let extraOptionSetOnly = Kind(rawValue: extraOptionSet)
        XCTAssertFalse(extraOptionSetOnly.isValidOptionSet)
    }
    
    func loadAndForEachMangles(_ inputFileName: String, forEach handler: (_ line: Int, _ mangled: String, _ demangled: String) throws -> Void) throws {
        let bundle = Bundle(for: SwiftDemangleTests.self)
        let path = bundle.path(forResource: inputFileName, ofType: "")!
        let tests = try String(contentsOfFile: path)
        for (offset, mangledPair) in tests.split(separator: "\n").enumerated() where mangledPair.isNotEmpty && !mangledPair.hasPrefix("//") {
            var range = mangledPair.range(of: " ---> ")
            if range == nil {
                range = mangledPair.range(of: " --> ")
            }
            if range == nil {
                range = mangledPair.range(of: " -> ")
            }
            guard let range = range else { continue }
            let mangled = String(mangledPair[mangledPair.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let demangled = String(mangledPair[range.upperBound..<mangledPair.endIndex])
            try handler(offset, mangled, demangled)
        }
    }
    
}
