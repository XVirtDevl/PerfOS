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


%define PH_NONE 0

%define PH_SAVE_NO_REGS (1<<0)
%define PH_SAVE_RAX (1<<8)
%define PH_SAVE_RBX (1<<9)
%define PH_SAVE_RCX (1<<10)
%define PH_SAVE_RDX (1<<11)
%define PH_SAVE_RSI (1<<12)
%define PH_SAVE_RDI (1<<13)

%define PH_DIVIDABLE_8 (1<<14)
%define PH_SHR_8 (1<<15) | PH_DIVIDABLE_8
%define PH_DIVIDABLE_4 (1<<18)
%define PH_LOAD_ALL (1<<16)
%define PH_SAVE_ALL (1<<17)


%define PH_LOAD_NO_REGS (1<<1)
%define PH_LOAD_RAX (1<<2)
%define PH_LOAD_RBX (1<<3)
%define PH_LOAD_RCX (1<<4)
%define PH_LOAD_RDX (1<<5)
%define PH_LOAD_RSI (1<<6)
%define PH_LOAD_RDI (1<<7)





%macro memset 3-4 PH_NONE
	%assign Hints (%4)
		%if (Hints & PH_SAVE_NO_REGS ) = 0
			%if Hints = PH_NONE
				push rdi
				push rax
				push rcx
			%elifn (Hints & PH_SAVE_ALL) = 0
				push rdi
				push rax
				push rcx
			%else
				%ifn (Hints & PH_SAVE_RDI ) = 0
					push rdi
				%endif
				%ifn (Hints & PH_SAVE_RAX ) = 0
					push rax
				%endif
				%ifn (Hints & PH_SAVE_RCX ) = 0
					push rcx
				%endif
			%endif
		%endif
		%if (Hints & PH_LOAD_NO_REGS) = 0
			%if Hints = PH_NONE
				mov rdi, %1
				mov rcx, %3
				mov rax, %2
			%elifn (Hints & PH_LOAD_ALL ) = 0
				mov rdi, %1
				mov rcx, %3
				mov rax, %2
			%else
				%ifn (Hints & PH_LOAD_RDI) = 0
					mov rdi, %1
				%endif
				%ifn (Hints & PH_LOAD_RCX ) = 0
					mov rcx, %3
				%endif
				%ifn (Hints & PH_LOAD_RAX ) = 0
					mov rax, %2
				%endif
			%endif
		%endif

		%ifn (Hints & PH_DIVIDABLE_8) = 0
			%if (Hints & PH_SHR_8) = 0
				shr rcx, 3
			%endif
			rep stosq
		%elif ( Hints & PH_DIVIDABLE_4 ) = PH_DIVIDABLE_4
			test cx, 0x7
			jz %%shf84

			mov dword[ rdi ], eax
			add rdi, 4

			%%shf84:
				shr rcx, 3
				rep stosq
		%else
			test cx, 0x7
			jz %%shf8

			%ifn (Hints = PH_NONE)
				%if (Hints & PH_SAVE_RCX) = 0
					%if (Hints & PH_SAVE_ALL) = 0
						push rcx
					%endif
				%endif
			%endif

			and rcx, 0x7
			rep stosb

			pop rcx

			%if ((Hints = PH_NONE ) || (Hints & PH_SAVE_RCX) = PH_SAVE_RCX || (Hints & PH_SAVE_ALL) = PH_SAVE_ALL )
				push rcx
			%endif

			and ecx, 0xFFFFFFF8

			%%shf8:
				shr rcx, 3
				rep stosq
		%endif

		%if Hints = PH_NONE
			pop rcx
			pop rax
			pop rdi
		%elifn (Hints & PH_SAVE_ALL ) = 0
			pop rcx
			pop rax
			pop rdi
		%else
			%ifn (Hints & PH_SAVE_RDI ) = 0
				pop rdi
			%endif
			%ifn (Hints & PH_SAVE_RAX ) = 0
				pop rax
			%endif
			%ifn (Hints & PH_SAVE_RCX ) = 0
				pop rcx
			%endif
		%endif
%endmacro



%macro memcpy 3-4 PH_NONE
	%assign Hints (%4)
		%if (Hints & PH_SAVE_NO_REGS ) = 0
			%if Hints = PH_NONE
				push rdi
				push rsi
				push rcx
			%elifn (Hints & PH_SAVE_ALL) = 0
				push rdi
				push rsi
				push rcx
			%else
				%ifn (Hints & PH_SAVE_RDI ) = 0
					push rdi
				%endif
				%ifn (Hints & PH_SAVE_RSI ) = 0
					push rsi
				%endif
				%ifn (Hints & PH_SAVE_RCX ) = 0
					push rcx
				%endif
			%endif
		%endif
		%if (Hints & PH_LOAD_NO_REGS) = 0
			%if Hints = PH_NONE
				mov rdi, %1
				mov rcx, %3
				mov rsi, %2
			%elifn (Hints & PH_LOAD_ALL ) = 0
				mov rdi, %1
				mov rcx, %3
				mov rsi, %2
			%else
				%ifn (Hints & PH_LOAD_RDI) = 0
					mov rdi, %1
				%endif
				%ifn (Hints & PH_LOAD_RCX ) = 0
					mov rcx, %3
				%endif
				%ifn (Hints & PH_LOAD_RSI ) = 0
					mov rsi, %2
				%endif
			%endif
		%endif

		%ifn (Hints & PH_DIVIDABLE_8) = 0
			%if (Hints & PH_SHR_8) = 0
				shr rcx, 3
			%endif
			rep movsq
		%elif (Hints & PH_DIVIDABLE_4 ) = PH_DIVIDABLE_4
		
			test cx, 0x7
			jz %%shf84

			push rcx
			mov ecx, dword[ rsi ]
			mov dword[ rdi ], ecx
			add rdi, 4
			add rsi, 4
			pop rcx

			%%shf84:
				shr rcx, 3
				rep movsq
		%else
			test cx, 0x7
			jz %%shf8

			%ifn (Hints = PH_NONE)
				%if (Hints & PH_SAVE_RCX) = 0
					%if (Hints & PH_SAVE_ALL) = 0
						push rcx
					%endif
				%endif
			%endif

			and rcx, 0x7
			rep movsb

			pop rcx

			%if ((Hints = PH_NONE ) || (Hints & PH_SAVE_RCX) = PH_SAVE_RCX || (Hints & PH_SAVE_ALL) = PH_SAVE_ALL )
				push rcx
			%endif

			and ecx, 0xFFFFFFF8

			%%shf8:
				shr rcx, 3
				rep movsq

		%endif

		%if Hints = PH_NONE
			pop rcx
			pop rsi
			pop rdi
		%elifn (Hints & PH_SAVE_ALL ) = 0
			pop rcx
			pop rsi
			pop rdi
		%else
			%ifn (Hints & PH_SAVE_RDI ) = 0
				pop rdi
			%endif
			%ifn (Hints & PH_SAVE_RSI ) = 0
				pop rsi
			%endif
			%ifn (Hints & PH_SAVE_RCX ) = 0
				pop rcx
			%endif
		%endif
%endmacro

%endif
