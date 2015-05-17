%ifndef _METAPROGRAMMING_KERNEL_INC_
%define _METAPROGRAMMING_KERNEL_INC_

%macro GUARDED_INCLUDE 2-*
	%rep %0-1
		%define %1
		%rotate 1
	%endrep
	%include %1
%endmacro

%macro EnrolledLoop 2
	%rep %1
	%2
	%endrep
%endmacro

%macro memcpy_size8 3
	push rdi
	push rsi
	push rcx

	mov rdi, %1
	mov rsi, %2
	mov rcx, %3

	shr rcx, 3

	rep movsq

	pop rcx
	pop rsi
	pop rdi

%endmacro

%macro memcpy 3
	push rdi
	push rsi
	push rcx

	mov rdi, %1
	mov rsi, %2
	mov rcx, %3

	test ecx, 0x7
	jz %local

	and cx, 0x7
	rep movsb

	pop rcx
	push rcx

	and cx, 0xFFF8

	%local:
		shr ecx, 3
		rep movsq

	pop rcx
	pop rsi
	pop rdi
%endmacro

%endif
