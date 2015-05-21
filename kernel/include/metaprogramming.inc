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


%macro memset_isRShift3 3
	%if %1 != rdi
		push rdi
	%endif

	%if %2 != rax
		push rax
	%endif

	%if %3 != rcx
		push rcx
	%endif

	%if %1 != rdi
		mov rdi, %1
	%endif

	%if %3 != rcx
		mov rcx, %3
	%endif

	%if %2 != rax
		mov rax, %2
	%endif

	rep stosq

	%if %3 != rcx
		pop rcx
	%endif

	%if %2 != rax
		pop rax
	%endif

	%if %1 != rdi
		pop rdi
	%endif
%endmacro



%macro memset_size8 3
	%if (%3 % 8 ) = 0
		memset_isRShift3 rdi, rax, (%3>>3)
	%else
		%if %1 != rdi
			push rdi
		%endif

		%if %2 != rax
			push rax
		%endif

		%if %3 != rcx
			push rcx
		%endif

		%if %1 != rdi
			mov rdi, %1
		%endif

		%if %3 != rcx
			mov rcx, %3
		%endif

		%if %2 != rax
			mov rax, %2
		%endif

		shr rcx, 3
		rep stosq

		%if %3 != rcx
			pop rcx
		%endif

		%if %2 != rax
			pop rax
		%endif

		%if %1 != rdi
			pop rdi
		%endif
	%endif
%endmacro


%macro memset 3
	%if %1 != rdi
		push rdi
	%endif

	%if %2 != rax
		push rax
	%endif

	push rcx

	%if %1 != rdi
		mov rdi, %1
	%endif

	%if %3 != rcx
		mov rcx, %3
	%endif

	%if %2 != rax
		mov rax, %2
	%endif

	test ecx, 0x7
	jz %%lc

	and cx, 0x7

	rep stosb

	pop rcx
	push rcx

	%%lc:
		and cx, 0xFFF8
		shr rcx, 3
		rep stosq

	pop rcx

	%if %2 != rax
		pop rax
	%endif

	%if %1 != rdi
		pop rdi
	%endif
%endmacro

%macro memcpy_isRShift3 3
	%if %1 != rdi
		push rdi
	%endif

	%if %2 != rsi
		push rsi
	%endif

	%if %3 != rcx
		push rcx
	%endif

	%if %1 != rdi
		mov rdi, %1
	%endif

	%if %3 != rcx
		mov rcx, %3
	%endif

	%if %2 != rsi
		mov rsi, %2
	%endif

	rep movsq

	%if %3 != rcx
		pop rcx
	%endif

	%if %2 != rsi
		pop rsi
	%endif

	%if %1 != rdi
		pop rdi
	%endif
%endmacro

%macro memcpy_size8 3
	%ifid %1
		%if %1 = rdi
			push rdi
		%endif
	%endif

	%ifn %2 = rsi
		push rsi
	%endif

	%ifn %3 = rcx
		push rcx
	%endif

	%ifn %1 = rdi
		mov rdi, %1
	%endif

	%ifn %3 = rcx
		mov rcx, %3
	%endif

	%ifn %2 = rsi
		mov rsi, %2
	%endif

	shr rcx, 3

	rep movsq


	%ifn %3 = rcx
		pop rcx
	%endif

	%ifn %2 = rsi
		pop rsi
	%endif

	%ifn %1 = rdi
		pop rdi
	%endif

%endmacro

%macro memcpy 3

	%ifnum %3
		%if (%3 % 8 ) = 0
			memcpy_isRShift3 %1, %2, (%3>>3)
		%else
			push rcx
			mov rcx, %3
			memcpy %1, %2, rcx
			pop rcx
		%endif
	%else

		%if %1 != rdi
			push rdi
		%endif

		%if %2 != rsi
			push rsi
		%endif

		push rcx

		%if %1 != rdi
			mov rdi, %1
		%endif

		%if %2 != rsi
			mov rsi, %2
		%endif

		%if %3 != rcx
			mov rcx, %3
		%endif

		test ecx, 0x7
		jz %%lc

		and cx, 0x7
		rep movsb

		pop rcx
		push rcx

		and cx, 0xFFF8

		%%lc:
			shr ecx, 3
			rep movsq

		pop rcx

		%if %2 != rsi 
			pop rsi
		%endif
	
		%if %1 != rdi
			pop rdi
		%endif
	%endif
%endmacro

%endif
