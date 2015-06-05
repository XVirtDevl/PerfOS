%ifndef _CALLING_CONVENTIONS_INC_
%define _CALLING_CONVENTIONS_INC_

%include "meta/debug.inc"

%macro DEFINE_STDCALL 1
	extern %1
	%macro %1 0
		%warning this function has the calling convention stdcall it must be called 
	%endmacro
%endmacro

%macro STDCALL 1-*
	%define CURTAIN_CALL %1

	%if %0 = 2
		mov rdi, %2
	%elif %0 = 3
		mov rdi, %2
		mov rsi, %3
	%elif %0 = 4
		mov rdi, %2
		mov rsi, %3
		mov rdx, %4
	%elif %0 = 5
		mov rdi, %2
		mov rsi, %3
		mov rdx, %4
		mov rcx, %5
	%elif %0 = 6
		mov rdi, %2
		mov rsi, %3
		mov rdx, %4
		mov rcx, %5
		mov r8, %6
	%elif %0 = 7
		mov rdi, %2
		mov rsi, %3
		mov rdx, %4
		mov rcx, %5
		mov r8, %6
		mov r9, %7
	%else
		mov rdi, %2
		mov rsi, %3
		mov rdx, %4
		mov rcx, %5
		mov r8, %6
		mov r9, %7

		%rep %0-7
			%rotate -1
			%push %1
		%endrep
	%endif

	OUT_OF_ORDER_CALL CURTAIN_CALL
%endmacro

%endif
