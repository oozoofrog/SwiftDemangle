import XCTest
@testable import SwiftDemangle

func catchTry<R>(_ procedure: @autoclosure () throws -> R, or: R) -> R {
    do {
        return try procedure()
    } catch {
        return or
    }
}

final class SwiftDemangleTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testPunycode() {
        let punycoded = "Proprostnemluvesky_uybCEdmaEBa"
        let encoded = "Pročprostěnemluvíčesky"
        XCTAssertEqual(Punycode(string: punycoded).decode(), encoded)
    }
    
    func testDemangle() throws {
        let mangled = "s7example1fyyYjfYaKF"
        let demangled = #"$s7example1fyyYjfYaKF"#
        let result = mangled.demangled
        XCTAssertEqual(result, demangled, "\(mangled) ---> expect: (\(demangled)), result: (\(result))")
    }
    
    func testDemanglingInAngleQuotationMarks() throws {
        let mangled = "<_TtC4TestP33_EBDFD10FF4CF0D65A8576F5ADD7EC0FF8TestView: 0x0; frame = (0 0; 404 67.3333); layer = <CALayer: 0x0>>"
        let demangled = "<Test.(TestView in _EBDFD10FF4CF0D65A8576F5ADD7EC0FF): 0x0; frame = (0 0; 404 67.3333); layer = <CALayer: 0x0>>"
        let result = mangled.demangled
        XCTAssertEqual(result, demangled, "\(mangled) ---> expect: (\(demangled)), result: (\(result))")
    }
    
    func testManglings() throws {
        try loadAndForEachMangles("manglings.txt") { line, mangled, demangled in
            var opts: DemangleOptions = .defaultOptions
            var result = catchTry(try mangled.demangling(opts), or: mangled)
            if result != demangled {
                opts.isClassify = true
                result = catchTry(try mangled.demangling(opts), or: mangled)
            }
            if result != demangled {
                print("[TEST] demangling for \(line):  \(mangled) failed")
            }
            XCTAssertEqual(result, demangled, """

            let mangled = "\(mangled)"
            let demangled = "\(demangled)"
            XCTAssertEqual(mangled.demangled, demangled)
            result = "\(result)"
            """)
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
            let result = mangled.demangled
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
        let bundle = Bundle.module
        let path = bundle.path(forResource: inputFileName, ofType: "")!
        let tests = try String(contentsOfFile: path)
        for (offset, mangledPair) in tests.split(separator: "\n").enumerated() where mangledPair.isNotEmpty && !mangledPair.hasPrefix("//") {
            let range = mangledPair.range(of: " ---> ")
            guard let rangePair = range else { continue }
            let mangled = String(mangledPair[mangledPair.startIndex..<rangePair.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let demangled = String(mangledPair[rangePair.upperBound..<mangledPair.endIndex])
            try handler(offset, mangled, demangled)
        }
    }

}
