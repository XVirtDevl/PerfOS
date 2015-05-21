%ifndef _DEBUG_INC_
%define _DEBUG_INC_

%macro TRACE_FUNC_CALL 1
	%ifndef FT_%1
		%define FT_%1
	%endif
%endmacro

%macro TRACE_MODULE_CALLS 1
	%ifndef MT_%1
		%define MT_%1
	%endif
%endmacro

%macro UNTRACE_MODULE_CALLS 1
	%undef MT_%1
%endmacro

%macro UNTRACE_FUNC_CALL 1
	%undef FT_%1
%endmacro

%macro CHECK_TRACE 2
	%ifdef FT_%1
		%define TRACE
	%else
		%ifdef MT_%2
			%define TRACE
		%else
			%undef TRACE
		%endif
	%endif
%endmacro


%macro DISABLE_NORMAL_FUNC_CALL 1
	%macro %1 0
		%error This function is disabled, please make use of a macro to call : Function used in file: __FILE__, line:  __LINE__
	%endmacro
%endmacro

%macro ENABLE_NORMAL_FUNC_CALL 1
	%unmacro %1 0
%endmacro

%macro OUT_OF_ORDER_CALL 1
	ENABLE_NORMAL_FUNC_CALL %1
	call %1
	DISABLE_NORMAL_FUNC_CALL %1
%endmacro

%endif
