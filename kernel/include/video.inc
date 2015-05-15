extern printf
%macro VPrintf 1-*
	mov rsi, %1	
	%rep %0-1
		%rotate 1
		push %1
	%endrep
	call printf
	add esp, %0*8
%endmacro


extern setScreenAttributes
%macro VSetScreenAttributes 1
	mov al, %1
	call setScreenAttributes
%endmacro

extern clearScreen
extern updateScreen

extern scrollScreen
%macro VScrollScreen 1
	mov eax, %1
	call scrollScreen
%endmacro

extern endl

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

