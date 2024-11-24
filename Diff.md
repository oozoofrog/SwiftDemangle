// added Kind in version 6.1
- [x] BodyAttachedMacroExpansion - body attached macro expansion
- [x] BuiltinTupleType - builtin tuple type for swift compiler
- [x] BuiltinFixedArray - builtin fixed array type for swift compiler
- [x] PackProtocolConformance - variadic generic pack protocol conformance
- [x] DependentGenericSameShapeRequirement - requirement that two generic types must have the same structural characteristics (e.g., identical property structure or memory layout)
- [x] DependentGenericParamPackMarker - marker for a variadic generic parameter pack
- [x] ImplErasedIsolation - isolation for any actor
- [x] ImplSendingResult - sending result for function
- [x] ImplParameterSending - sending parameter for function
- [x] ImplCoroutineKind - coroutine kind for ast (yield_once, yield_once_2, yield_many)
- [x] InitAccessor - managing for lazy initializer accessor
- [x] IsolatedDeallocator - isolated deallocator for any actor
- [x] Sending - sending for function
- [x] IsolatedAnyFunctionType - isolated any function type
- [x] SendingResultFunctionType - sending result function type
- [x] MacroExpansionLoc - print location of macro expansion
- [x] Modify2Accessor - modify2: improved version of modify accessor
- [x] PreambleAttachedMacroExpansion
- [x] Read2Accessor - read accessor for coroutine
- [x] Pack - generic pack
- [x] SILPackDirect - direct SIL pack
- [x] SILPackIndirect - indirect SIL pack
- [x] PackExpansion - pack expansion
- [x] PackElement - pack element
- [x] PackElementLevel - pack element level
/// note: old mangling only
- [x] VTableAttribute - override attribute
- [x] SILThunkIdentity - identity thunk for ABI
- [x] SILThunkHopToMainActorIfNeeded - hop to main actor thunk
- [x] TypedThrowsAnnotation - print typed throws
- [x] SugaredParen // Removed in Swift 6.TBD
- [x] DroppedArgument
// Addedn in Swift 6.0
- [x] OutlinedEnumTagStore
- [x] OutlinedEnumProjectDataForLoad
- [x] OutlinedEnumGetTag
// Added in Swift 5.9 1
- [x] AsyncRemoved
// Added in Swift 5.TBD
- [x] ObjectiveCProtocolSymbolicReference - objective-c protocol symbolic reference
- [x] OutlinedInitializeWithCopyNoValueWitness
- [ ] OutlinedAssignWithTakeNoValueWitness
- [ ] OutlinedAssignWithCopyNoValueWitness
- [ ] OutlinedDestroyNoValueWitness
- [ ] DependentGenericInverseConformanceRequirement
// Added in Swift 6.TBD
- [ ] Integer
- [ ] NegativeInteger
- [ ] DependentGenericParamValueMarker
