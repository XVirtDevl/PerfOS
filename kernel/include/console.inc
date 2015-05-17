%ifndef CONSOLE_EXPORT_FUNCTIONALITY
%define CONSOLE_EXPORT_FUNCTIONALITY

extern SetScreenDimensions
extern SetTextAttributes
extern SetBufferedOutputBuffer
extern SetBufferedOutputFlags
extern UpdateScreen
extern printf

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

%define CF_BUFFERED_OUTPUT (1<<0)
%define CF_STAGE_IN_BUFFER_FOR_SCREEN (1<<1)


%define CF_NO_BUFFERED_OUTPUT 0
