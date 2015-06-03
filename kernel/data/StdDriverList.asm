%include "meta/metaprogramming.inc"

GUARDED_INCLUDE _STDKERNEL_EXPORT_, "StdDriverList.inc"

global RegisteredDrivers
RegisteredDrivers:
	times RegisteredDriversStruct_size db 0
