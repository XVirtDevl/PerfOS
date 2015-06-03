%ifndef _METAPROGRAMMING_STACK_INC_
%define _METAPROGRAMMING_STACK_INC_

%macro CREATE_STACK 1
	%push %1
	push rbp
	mov rbp, rsp 

	%ifdef STACK_%1
		%error there is alraedy a stack with the name %1
	%endif
	%define STACK_%1
	%define %$STACK_NAME %1	
	%xdefine %$STACK_SIZE_CURR 0
	%xdefine %$STACK_SIZE_FLOAT 0
%endmacro

%macro RESERVE_STACK_SPACE 2
	INTERN_STACK_SPACE %1, %2, %$STACK_NAME
%endmacro

%macro INTERN_STACK_SPACE 3
	%xdefine %$STACK_SIZE_FLOAT (%$STACK_SIZE_FLOAT + %2)
	%xdefine %$%1 %$STACK_SIZE_FLOAT
	%xdefine %3_%1 0
	%xdefine %$%1_OBJ_SIZE %2
%endmacro

%macro APPLY_STACK_CHANGE 0
	%ifn %$STACK_SIZE_FLOAT = %$STACK_SIZE_CURR
		sub rsp, (%$STACK_SIZE_FLOAT-%$STACK_SIZE_CURR)
		%xdefine %$STACK_SIZE_CURR %$STACK_SIZE_FLOAT
	%endif
%endmacro


%macro lea_s 2
	intern_lea_s %1, %2, %$STACK_NAME
%endmacro

%macro intern_lea_s 3
	APPLY_STACK_CHANGE
	%ifdef %3_%2
		%ifdef %3_%1
			mov [rbp - %$%1 ], -(%$%2)
			add qword[rbp - %$%1 ], rbp
		%else
			mov %1, -(%$%2)
			add %1, rbp
		%endif
	%else
		push rbx
		lea rbx, %2
		mov [rbp - %$%1 ], rbx
		pop rbx
	%endif
%endmacro

%macro intern_mov_s 3-4
	APPLY_STACK_CHANGE
	%if %0 = 3
		%xdefine OFFSET 0
	%else
		%xdefine OFFSET %4
	%endif
	%ifdef %3_%1
		mov [rbp - %$%1 + OFFSET ], %2
	%else
		mov %1, [rbp - %$%2 + OFFSET ]
	%endif
%endmacro

%macro mov_s 2-3
	%if %0 = 3
		intern_mov_s %1, %2, %$STACK_NAME, %3
	%else
		intern_mov_s %1, %2, %$STACK_NAME
	%endif
%endmacro

%macro intern_add_s 3-4
	APPLY_STACK_CHANGE

	%if %0 = 3
		%xdefine OFFSET 0
	%else
		%xdefine OFFSET %4
	%endif

	%ifdef %3_%1
		add [rbp - %$%1 + OFFSET ], %2
	%else
		add %1, [rbp - %$%2 + OFFSET ]
	%endif
%endmacro

%macro add_s 2-3
	%if %0 = 3
		intern_add_s %1, %2, %$STACK_NAME, %3
	%else
		intern_add_s %1, %2, %$STACK_NAME
	%endif
%endmacro


%macro DESTROY_STACK 1
	%pop %1
	%undef STACK_%1
	mov rsp, rbp
	pop rbp
%endmacro

%endif
