import Testing
import XCTest
@testable import SwiftDemangle

func catchTry<R>(_ procedure: @autoclosure () throws -> R, or: R) -> R {
    do {
        return try procedure()
    } catch {
        return or
    }
}

@MainActor
final class SwiftDemangleTests {
    
    @Test
    func testPunycode() {
        let punycoded = "Proprostnemluvesky_uybCEdmaEBa"
        let encoded = "Pročprostěnemluvíčesky"
        // XCTAssertEqual(Punycode(string: punycoded).decode(), encoded)
        #expect(Punycode(string: punycoded).decode() == encoded)
    }
    
    @Test
    func testDemangle() throws {
        let mangled = "s7example1fyyYjfYaKF"
        let demangled = #"$s7example1fyyYjfYaKF"#
        let result = mangled.demangled
//        XCTAssertEqual(result, demangled, "\(mangled) ---> expect: (\(demangled)), result: (\(result))")
        #expect(result == demangled)
    }
    
    @Test
    func testDemanglingInAngleQuotationMarks() throws {
        let mangled = "<_TtC4TestP33_EBDFD10FF4CF0D65A8576F5ADD7EC0FF8TestView: 0x0; frame = (0 0; 404 67.3333); layer = <CALayer: 0x0>>"
        let demangled = "<Test.(TestView in _EBDFD10FF4CF0D65A8576F5ADD7EC0FF): 0x0; frame = (0 0; 404 67.3333); layer = <CALayer: 0x0>>"
        let result = mangled.demangled
//        XCTAssertEqual(result, demangled, "\(mangled) ---> expect: (\(demangled)), result: (\(result))")
        #expect(result == demangled)
    }
    
    @Test
    func testManglings() throws {
        try loadAndForEachMangles("manglings.txt") { line, mangled, demangled in
            var result = try mangled.demangling(.defaultOptions)
            if result != demangled {
                let classifiedResult = try mangled.demangling(.defaultOptions.classified())
                result = classifiedResult
            }
            if result != demangled {
                print("[FAILURE] demangling for \(line):  \(mangled) ---> \(demangled) failed")
                print()
                print("R: " + result)
                print("E: " + demangled)
                print()
                #expect(Bool(false))
                return false
            }
            #expect(result == demangled)
            return true
        }
    }
    
    @Test
    func testSimplifiedManglings() throws {
        try loadAndForEachMangles("simplified-manglings.txt") { line, mangled, demangled in
            let opts: DemangleOptions = .simplifiedOptions
            let result = try mangled.demangling(opts)
            if result != demangled {
                print("[TEST] simplified demangle for \(line): \(mangled) failed")
                return false
            }
            #expect(result == demangled, """

            func test\(mangled)() throws {
                let mangled = "\(mangled)"
                let demangled = "\(demangled)"
                let result = try mangled.demangling(.simplifiedOptions, printDebugInformation: true)
                // \(result)
                XCTAssertEqual(result, demangled)
            }
            """)
            return true
        }
    }
    
    @Test
    func testManglingsWithClangTypes() throws {
        try loadAndForEachMangles("manglings-with-clang-types.txt") { line, mangled, demangled in
            let result = mangled.demangled
            if result != demangled {
                print("[TEST] mangled_with_clang_type demangle for \(line): \(mangled) failed")
                return false
            }
            #expect(result == demangled)
            return true
        }
    }
    
    @Test
    func testExperimentalManglings() throws {
        try loadAndForEachMangles("experimental-manglings.txt") { line, mangled, demangled in
            var result = try mangled.demangling(.defaultOptions)
            if result != demangled {
                let classifiedResult = try mangled.demangling(.defaultOptions.classified())
                result = classifiedResult
            }
            if result != demangled {
                print("[EXPERIMENTAL] demangling for \(line):  \(mangled) ---> \(demangled) failed")
                print()
                print("R: " + result)
                print("E: " + demangled)
                print()
                #expect(Bool(false))
                return false
            }
            #expect(result == demangled)
            return true
        }
    }

    @Test
    func testFunctionSigSpecializationParamKind() throws {
        typealias Kind = FunctionSigSpecializationParamKind
        
        let kindOnly = Kind(rawValue: Kind.Kind.ClosureProp.rawValue)
        #expect(kindOnly.kind == .ClosureProp)
        #expect(kindOnly.optionSet.isEmpty)
        
        let optionSet: Kind.OptionSet = [.Dead, .GuaranteedToOwned]
        let kindAndOptionSet = Kind(rawValue: Kind.Kind.ClosureProp.rawValue | optionSet.rawValue)
        
        #expect(kindAndOptionSet.kind != .ClosureProp)
        #expect(kindAndOptionSet.kind != .BoxToStack)
        #expect(kindAndOptionSet.kind != .BoxToValue)
        #expect(kindAndOptionSet.kind != .ConstantPropFloat)
        #expect(kindAndOptionSet.kind != .ConstantPropFunction)
        #expect(kindAndOptionSet.kind != .ConstantPropGlobal)
        #expect(kindAndOptionSet.kind != .ConstantPropInteger)
        #expect(kindAndOptionSet.kind != .ConstantPropString)
        
        #expect(kindAndOptionSet.containOptions(.Dead))
        #expect(kindAndOptionSet.containOptions(.GuaranteedToOwned))
        #expect(kindAndOptionSet.containOptions(.ExistentialToGeneric) == false)
        #expect(kindAndOptionSet.containOptions(.OwnedToGuaranteed) == false)
        #expect(kindAndOptionSet.containOptions(.SROA) == false)
        
        #expect(kindAndOptionSet.isValidOptionSet)
        
        let extraOptionSet: UInt = 1 << 11
        let extraOptionSetOnly = Kind(rawValue: extraOptionSet)
        #expect(extraOptionSetOnly.isValidOptionSet == false)
    }
    
    func loadAndForEachMangles(_ inputFileName: String, forEach handler: (_ line: Int, _ mangled: String, _ demangled: String) throws -> Bool) throws {
        let bundle = Bundle.module
        let path = bundle.path(forResource: inputFileName, ofType: "")!
        let tests = try String(contentsOfFile: path)
        for (offset, mangledPair) in tests.split(separator: "\n").enumerated() where mangledPair.isNotEmpty && !mangledPair.hasPrefix("//") {
            let range = mangledPair.range(of: " ---> ")
            guard let rangePair = range else { continue }
            let mangled = String(mangledPair[mangledPair.startIndex..<rangePair.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let demangled = String(mangledPair[rangePair.upperBound..<mangledPair.endIndex])
            let result = try handler(offset, mangled, demangled)
            if result == false {
                break
            }
        }
    }

}
