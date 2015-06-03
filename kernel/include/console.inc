%include "meta/debug.inc"


%ifndef CONSOLE_EXPORT_FUNCTIONALITY
%define CONSOLE_EXPORT_FUNCTIONALITY

%include "meta/metaprogramming.inc"

%xdefine MODULE_NAME CONSOLE

extern Console@64_PolymorphicList
%define SCROLL_SCREEN 0
%define UPDATE_SCREEN 8
%define PRINTF 16

%macro CScrollScreen 1
	mov eax, %1

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning Scrolling screen by %1
	%endif

	call qword[ Console@64_PolymorphicList + SCROLL_SCREEN ]

%endmacro

extern SetAutoscroll
DISABLE_NORMAL_FUNC_CALL SetAutoscroll
%macro CSetAutoscroll 1
	mov eax, %1

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%if %1 = 0
			%warning Screen autoscroll is set to off
		%else
			%warning Screen autoscroll is set to on
		%endif
	%endif

	OUT_OF_ORDER_CALL SetAutoscroll

%endmacro

extern SetScreenDimensions
DISABLE_NORMAL_FUNC_CALL SetScreenDimensions
%macro CSetScreenDimensions 4
	mov rax, %1
	mov bh, %2
	mov bl, %3
	mov rcx, %4

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
	%warning Base address = %1, Y Resolution = %2, X Resolution = %3, Screen length = %4 :: File: __FILE__ :-: Line: __LINE__
	%endif

	OUT_OF_ORDER_CALL SetScreenDimensions
%endmacro

extern SetTextAttributes
DISABLE_NORMAL_FUNC_CALL SetTextAttributes
%macro CSetTextAttributes 1
	mov ah, %1

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
	%warning New Text attributes = %1
	%endif

	OUT_OF_ORDER_CALL SetTextAttributes
%endmacro

extern SetBufferedOutputBuffer
DISABLE_NORMAL_FUNC_CALL SetBufferedOutputBuffer
%macro CSetBufferedOutputBuffer 2
	mov rdi, %1
	mov rcx, %2

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning Buffered output buffer address = %1, Size = %2
	%endif

	OUT_OF_ORDER_CALL SetBufferedOutputBuffer
%endmacro


extern SetBufferedOutputFlags
DISABLE_NORMAL_FUNC_CALL SetBufferedOutputFlags
%macro CSetBufferedOutputFlags 1

	mov eax, %1

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning New buffered output flags = %1
	%endif

	OUT_OF_ORDER_CALL SetBufferedOutputFlags
%endmacro

%macro CUpdateScreen 0
	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning Updating screen, streaming datat in buffer to the screen
	%endif

	call qword[ Console@64_PolymorphicList + UPDATE_SCREEN ]

%endmacro


extern ConvertNumberToHexStr32
DISABLE_NORMAL_FUNC_CALL ConvertNumberToHexStr32
%macro CIntToHexStr32 2
	mov rdi, %1
	mov rax, %2

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning Buffer address( at least 11 Bytes ) = %1 Number = %2
	%endif
	OUT_OF_ORDER_CALL ConvertNumberToHexStr32
%endmacro

extern ConvertNumberToHexStr64
DISABLE_NORMAL_FUNC_CALL ConvertNumberToHexStr64
%macro CIntToHexStr64 2
	mov rdi, %1
	mov rax, %2
	
	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning Buffer address( at least 19 Bytes ) = %1 Number = %2
	%endif
	OUT_OF_ORDER_CALL ConvertNumberToHexStr64
%endmacro

%macro CPrintf 1-*
	mov rsi, %1

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
	%warning String address: %1
	%endif
	%rep %0-1
		%rotate -1
		%ifdef TRACE
		%warning Pushed on the stack : %1
		%endif
		push %1
	%endrep
	call qword[ Console@64_PolymorphicList + PRINTF ]
	add esp, (%0-1)*8
%endmacro

extern ClearScreen
DISABLE_NORMAL_FUNC_CALL ClearScreen
%macro CClearScreen 0

	CHECK_TRACE %??, MODULE_NAME

	%ifdef TRACE
		%warning clearing screen but not the buffer!
	%endif

	OUT_OF_ORDER_CALL ClearScreen
%endmacro


%endif


%define COLOR_BLACK 0
%define COLOR_BLUE 1
%define COLOR_GREEN 2
%define COLOR_TURQUIS 3
%define COLOR_RED 4
%define COLOR_MAGENTA 5
%define COLOR_BROWN 6
%define COLOR_LIGHTGREY 7
%define COLOR_GREY 8
%define COLOR_LIGHTBLUE 9
%define COLOR_LIGHTGREEN 10
%define COLOR_LIGHTTURQUIS 11
%define COLOR_LIGHTRED 12
%define COLOR_LIGHTMAGENTA 13
%define COLOR_YELLOW 14
%define COLOR_WHITE 15

%define COLOR_PAIR(back,fore) (back<<4|fore)

%define CONSOLE_NEWLINE_CHAR 0x0A			; If this character is in any string printed then the 0x0A will be replaced by a new line
%define CONSOLE_NEWCOLOR_CHAR 0x17			; The byte following this character will specify the new color 
%define CONSOLE_NEWCOLOR(x,y) 0x17, (x<<4)|y

%define CF_BUFFERED_OUTPUT (1<<0)
%define CF_STAGE_IN_BUFFER_FOR_SCREEN (1<<1)


%define CF_NO_BUFFERED_OUTPUT 0

