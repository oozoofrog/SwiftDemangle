//
//  Node+Payload.swift
//  Demangling
//

import Foundation

extension Node {
    public enum Payload: Equatable, CustomDebugStringConvertible {
        case none
        case text(String)
        case index(UInt64)
        case valueWitnessKind(ValueWitnessKind)
        case mangledDifferentiabilityKind(MangledDifferentiabilityKind)
        case functionSigSpecializationParamKind(FunctionSigSpecializationParamKind)
        case directness(Directness)
        case onechild
        case twochildren
        case manychildren
        
        var isChildren: Bool {
            switch self {
            case .none, .onechild, .twochildren, .manychildren:
                return true
            default:
                return false
            }
        }
        
        var isText: Bool {
            switch self {
            case .text: return true
            default: return false
            }
        }
        
        var hasValue: Bool {
            switch self {
            case .text, .index:
                return true
            default:
                return false
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .text(let value):
                return "text:\"\(value)\""
            case .index(let value):
                return "index:\(value)"
            default:
                return ""
            }
        }
    }

    public enum IsVariadic {
        case yes, no
    }
    
    public enum Directness {
        case direct, indirect, unknown
        
        var text: String {
            switch self {
            case .direct:
                return "direct"
            case .indirect:
                return "indirect"
            case .unknown:
                return ""
            }
        }
    }
    
    public enum ValueWitnessKind {
        case AllocateBuffer
        case AssignWithCopy
        case AssignWithTake
        case DeallocateBuffer
        case Destroy
        case DestroyBuffer
        case DestroyArray
        case InitializeBufferWithCopyOfBuffer
        case InitializeBufferWithCopy
        case InitializeWithCopy
        case InitializeBufferWithTake
        case InitializeWithTake
        case ProjectBuffer
        case InitializeBufferWithTakeOfBuffer
        case InitializeArrayWithCopy
        case InitializeArrayWithTakeFrontToBack
        case InitializeArrayWithTakeBackToFront
        case StoreExtraInhabitant
        case GetExtraInhabitantIndex
        case GetEnumTag
        case DestructiveProjectEnumData
        case DestructiveInjectEnumTag
        case GetEnumTagSinglePayload
        case StoreEnumTagSinglePayload
        
        init?(code: String) {
            switch code {
            case "al": self = .AllocateBuffer
            case "ca": self = .AssignWithCopy
            case "ta": self = .AssignWithTake
            case "de": self = .DeallocateBuffer
            case "xx": self = .Destroy
            case "XX": self = .DestroyBuffer
            case "Xx": self = .DestroyArray
            case "CP": self = .InitializeBufferWithCopyOfBuffer
            case "Cp": self = .InitializeBufferWithCopy
            case "cp": self = .InitializeWithCopy
            case "Tk": self = .InitializeBufferWithTake
            case "tk": self = .InitializeWithTake
            case "pr": self = .ProjectBuffer
            case "TK": self = .InitializeBufferWithTakeOfBuffer
            case "Cc": self = .InitializeArrayWithCopy
            case "Tt": self = .InitializeArrayWithTakeFrontToBack
            case "tT": self = .InitializeArrayWithTakeBackToFront
            case "xs": self = .StoreExtraInhabitant
            case "xg": self = .GetExtraInhabitantIndex
            case "ug": self = .GetEnumTag
            case "up": self = .DestructiveProjectEnumData
            case "ui": self = .DestructiveInjectEnumTag
            case "et": self = .GetEnumTagSinglePayload
            case "st": self = .StoreEnumTagSinglePayload
            default:
                return nil
            }
        }
        
        var name: String {
            switch self {
            case .AllocateBuffer:
                return "AllocateBuffer".lowercasedOnlyFirst()
            case .AssignWithCopy:
                return "AssignWithCopy".lowercasedOnlyFirst()
            case .AssignWithTake:
                return "AssignWithTake".lowercasedOnlyFirst()
            case .DeallocateBuffer:
                return "DeallocateBuffer".lowercasedOnlyFirst()
            case .Destroy:
                return "Destroy".lowercasedOnlyFirst()
            case .DestroyBuffer:
                return "DestroyBuffer".lowercasedOnlyFirst()
            case .DestroyArray:
                return "DestroyArray".lowercasedOnlyFirst()
            case .InitializeBufferWithCopyOfBuffer:
                return "InitializeBufferWithCopyOfBuffer".lowercasedOnlyFirst()
            case .InitializeBufferWithCopy:
                return "InitializeBufferWithCopy".lowercasedOnlyFirst()
            case .InitializeWithCopy:
                return "InitializeWithCopy".lowercasedOnlyFirst()
            case .InitializeBufferWithTake:
                return "InitializeBufferWithTake".lowercasedOnlyFirst()
            case .InitializeWithTake:
                return "InitializeWithTake".lowercasedOnlyFirst()
            case .ProjectBuffer:
                return "ProjectBuffer".lowercasedOnlyFirst()
            case .InitializeBufferWithTakeOfBuffer:
                return "InitializeBufferWithTakeOfBuffer".lowercasedOnlyFirst()
            case .InitializeArrayWithCopy:
                return "InitializeArrayWithCopy".lowercasedOnlyFirst()
            case .InitializeArrayWithTakeFrontToBack:
                return "InitializeArrayWithTakeFrontToBack".lowercasedOnlyFirst()
            case .InitializeArrayWithTakeBackToFront:
                return "InitializeArrayWithTakeBackToFront".lowercasedOnlyFirst()
            case .StoreExtraInhabitant:
                return "StoreExtraInhabitant".lowercasedOnlyFirst()
            case .GetExtraInhabitantIndex:
                return "GetExtraInhabitantIndex".lowercasedOnlyFirst()
            case .GetEnumTag:
                return "GetEnumTag".lowercasedOnlyFirst()
            case .DestructiveProjectEnumData:
                return "DestructiveProjectEnumData".lowercasedOnlyFirst()
            case .DestructiveInjectEnumTag:
                return "DestructiveInjectEnumTag".lowercasedOnlyFirst()
            case .GetEnumTagSinglePayload:
                return "GetEnumTagSinglePayload".lowercasedOnlyFirst()
            case .StoreEnumTagSinglePayload:
                return "StoreEnumTagSinglePayload".lowercasedOnlyFirst()
            }
        }
    }
}
