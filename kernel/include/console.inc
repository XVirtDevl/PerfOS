%ifndef CONSOLE_EXPORT_FUNCTIONALITY
%define CONSOLE_EXPORT_FUNCTIONALITY

extern SetScreenDimensions

extern SetTextAttributes
%macro VSetTextAttributes 1
	mov ah, %1
	call SetTextAttributes
%endmacro

extern SetBufferedOutputBuffer
extern SetBufferedOutputFlags
extern UpdateScreen


extern ConvertNumberToHexStr32

%macro IntToHexStr32 2
	mov rdi, %1
	mov rax, %2
	call ConvertNumberToHexStr32
%endmacro

extern ConvertNumberToHexStr64


%macro IntToHexStr64 2
	mov rdi, %1
	mov rax, %2
	call ConvertNumberToHexStr64
%endmacro

extern printf
%macro VPrintf 1-*
	mov rsi, %1
	%rep %0-1
		%rotate -1
		push %1
	%endrep
	call printf
	add esp, (%0-1)*8

%endmacro

extern ClearScreen

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
