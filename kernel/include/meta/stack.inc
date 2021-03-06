%ifndef _METAPROGRAMMING_STACK_INC_
%define _METAPROGRAMMING_STACK_INC_


%macro REGISTER_STRUC 3
	RESERVE_STACK_SPACE %2, %1_size
	ASSIGN_SPACE_STRUC %2, %1
	%if %0 = 3
		REGISTER_DESTRUCTOR %$STACK_NAME, %2, %3
	%endif
%endmacro

%macro REGISTER_DESTRUCTOR 3
	%define %1_%2_DESTRUCTOR %3
	%ifndef %1_DESTRUCTOR_LIST
		%xdefine %1_DESTRUCTOR_LIST CALL_DESTRUCTORS %2
	%else
		%xdefine %1_DESTRUCTOR_LIST %1_DESTRUCTOR_LIST, %2
	%endif
%endmacro


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

%macro ASSIGN_SPACE_STRUC 2
	INTERN_ASSIGN_SPACE_STRUC %1, %2, %$STACK_NAME
%endmacro

%macro INTERN_ASSIGN_SPACE_STRUC 3
	%ifdef %3_%1
		%xdefine %$STRUC_%1 %2
	%else
		%warning unknown stack variable %1
	%endif
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

%define sizeof(x) (%$ %+ x %+ _OBJ_SIZE)


%macro lea_s 2
	intern_lea_s %1, %2, %$STACK_NAME
%endmacro

%macro intern_lea_s 3
	APPLY_STACK_CHANGE
	
	%xdefine OFFSET 0
	%xdefine OFFSET1 0
	HasPoint %2
	%xdefine VARIABLE0 %2
	%xdefine OFFSET 0
	%if HAS_POINT = 1
		DivideStrings %2, VARIABLE0, CLASS0
		%xdefine STRUCTURE0 %$STRUC_ %+ VARIABLE0
		%xdefine OFFSET (OFFSET + (STRUCTURE0 %+ . %+ CLASS0))
	%endif
	

	IFDEF %3, VARIABLE0
	%if IS_DEFINED = 1
		HasPoint %1
		%xdefine VARIABLE1 %1
		%if HAS_POINT = 1
			DivideStrings %1, VARIABLE1, CLASS1
			%xdefine STRUCTURE1 %$STRUC_ %+ VARIABLE1
			%xdefine OFFSET1 (STRUCTURE1 %+ . %+ CLASS1)
		%endif


		IFDEF %3, VARIABLE1
		%if IS_DEFINED = 1
			mov qword[rbp - (%$ %+ VARIABLE1) + OFFSET1 ], -((%$ %+ VARIABLE0) - OFFSET)
			add qword[rbp - (%$ %+ VARIABLE1) + OFFSET1 ], rbp
		%else
			mov %1, -((%$ %+ VARIABLE0) - OFFSET)
			add %1, rbp
		%endif
	%else
		push rbx
		lea rbx, %2	
		HasPoint %1
		%xdefine VARIABLE1 %1
		%if HAS_POINT = 1
			DivideStrings %1, VARIABLE1, CLASS1
			%xdefine STRUCTURE1 %$STRUC_ %+ VARIABLE1
			%xdefine OFFSET (OFFSET + (STRUCTURE1 %+ . %+ CLASS1))
		%endif

		mov qword[rbp - (%$ %+ VARIABLE1) + OFFSET ], rbx
		pop rbx
	%endif

	%undef %2
	%undef %1
%endmacro


%macro sub_s 2
	mac_pattern sub, %1, %2
%endmacro

%macro add_s 2
	mac_pattern add, %1, %2
%endmacro

%macro mov_s 2
	mac_pattern mov, %1, %2
%endmacro

%macro mac_pattern 3
		%macro intern_%1_s 3
			APPLY_STACK_CHANGE
			SEARCH_REPLACE_STACK %2
			%deftok ENDTOK1 EndStr
			SEARCH_REPLACE_STACK %3
			%deftok ENDTOK2 EndStr

			%1 ENDTOK1, ENDTOK2
		%endmacro
		intern_%1_s %1, %2, %3
		%unmacro intern_%1_s 3
%endmacro


%macro SEARCH_REPLACE_STACK 1
	%defstr thisStr %1
	%define EndStr thisStr
	%xdefine countStart 1
	%xdefine semiCounter 1
	%xdefine NEED_CHANGE 0
	CUT_WHITESPACES thisStr
	%define thisStr NewStr
	%strlen charcnt thisStr
	%rep charcnt
		%substr mypoint thisStr semiCounter
		%if mypoint = '['
			%xdefine NEED_CHANGE 1
		%endif

		%if mypoint = ']'
			%xdefine NEED_CHANGE 1
		%endif
	
		%if mypoint = '+'
			%xdefine NEED_CHANGE 1
		%endif
	
		%if mypoint = '-'
			%xdefine NEED_CHANGE 1
		%endif
	

		%if NEED_CHANGE = 1
			%xdefine NEED_CHANGE 0
			%substr CheckStr thisStr countStart, (semiCounter-countStart)
			%deftok CheckTok CheckStr
			CHECK_AND_REPLACE %$STACK_NAME, CheckTok
			%ifdef REPLACE
				%substr EndStr thisStr 1, countStart-1
				%strcat EndStr EndStr, REPLACE_STR
				%substr next thisStr semiCounter,charcnt
				%strcat EndStr EndStr, next
			%endif
			%xdefine countStart (semiCounter+1)
		%endif
		%xdefine semiCounter (semiCounter+1)
	%endrep
%endmacro

%macro CHECK_AND_REPLACE 2
	%ifdef %1_%2
		%xdefine REPLACE rbp - (%$%2)
		%defstr REPLACE_STR REPLACE
	%else
		%xdefine OFFSET1 0
		HasPoint %2
		%xdefine VARIABLE1 %2
		%if HAS_POINT = 1
			DivideStrings %2, VARIABLE1, CLASS1
			%xdefine STRUCTURE1 %$STRUC_ %+ VARIABLE1
			%xdefine OFFSET1 (STRUCTURE1 %+ . %+ CLASS1)
		%endif

		IFDEF %1, VARIABLE1
		%if IS_DEFINED = 1
			%xdefine REPLACE rbp - (%$ %+ VARIABLE1) + OFFSET1
			%defstr REPLACE_STR REPLACE
			%undef %2
		%else
			%undef REPLACE
			%undef REPLACE_STR
		%endif
	%endif
	
%endmacro

%macro CUT_WHITESPACES 1
	%strlen CHAR_WHITE %1
	%define NewStr ''
	%xdefine counter_white 1
	%rep CHAR_WHITE
		%substr mypoint %1 counter_white
		%ifn mypoint = ' '
			%strcat NewStr NewStr, mypoint
		%endif
		%xdefine counter_white counter_white+1
	%endrep
%endmacro

%macro IFDEF 2
	%ifdef %1_%2
		%xdefine IS_DEFINED 1
	%else
		%xdefine IS_DEFINED 0
	%endif
%endmacro

%macro HasPoint 1
	%defstr KthisStr %1
	%xdefine counter 1
	%strlen charcnt KthisStr
	%xdefine HAS_POINT 0
	%rep charcnt
		%substr mypoint KthisStr counter
		%if mypoint = '.'
			%xdefine HAS_POINT 1
		%endif
		%xdefine counter counter+1
	%endrep
%endmacro

%macro DivideStrings 3
	%defstr KthisStr %1
	%xdefine counter 1
	%strlen charcnt KthisStr
	%rep charcnt
		%substr mypoint KthisStr counter
		%if mypoint = '.'
			%substr STR0 KthisStr 1, counter-1
			%substr STR1 KthisStr counter+1, charcnt
			%deftok %2 STR0
			%deftok %3 STR1
		%endif
		%xdefine counter counter+1
	%endrep
%endmacro

%macro CALL_DESTRUCTORS 0-*	
	%rep %0
		lea_s rcx, %1
		CALL_DST %$STACK_NAME, %1
		%rotate 1
	%endrep
%endmacro

%macro CALL_DST 2
	%ifmacro %1_%2_DESTRUCTOR
		%1_%2_DESTRUCTOR rcx
	%else
		call %1_%2_DESTRUCTOR
	%endif
%endmacro

%macro DESTROY_STACK 1
	%ifdef %1_DESTRUCTOR_LIST
		%1_DESTRUCTOR_LIST
	%endif

	%pop %1
	%undef STACK_%1
	mov rsp, rbp
	pop rbp
%endmacro

%endif
