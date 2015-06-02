%ifndef _SYSCALL_TABLE_INCLUDE_
%define _SYSCALL_TABLE_INCLUDE_

	%ifndef EXPORT_FUNCTIONALITY_SYSCALL
	%define EXPORT_FUNCTIONALITY_SYSCALL
		extern PolymorphicList
	%endif

struc PolymorphicFuncList
	.allocMemory resq 1
	.freeMemory resq 1
endstruc

struc PolymorphicFuncListThread
	.singleReg resb PolymorphicFuncList_size
endstruc

%assign SYSCALL_COUNT 0

%macro REGISTER_SYSCALL 2
	%define SYSCALL_%1 PolymorphicFuncList.%2
%endmacro


%endif
