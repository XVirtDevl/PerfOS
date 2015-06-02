%include "metaprogramming.inc"

GUARDED_INCLUDE EXPORT_FUNCTIONALITY_SYSCALL, "syscallTable.inc"

section polyMorphicFct
global PolymorphicList
PolymorphicList:
	istruc PolymorphicFuncList
		at .
	iend
