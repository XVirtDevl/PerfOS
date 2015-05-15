extern setIDTGate
%macro ASetIDTGate 2
	mov rdi, %1
	mov rcx, %2
	call setIDTGate
%endmacro


extern setIDTBase
%macro ASetIDTBase 1
	mov rdi, %1
	call setIDTBase
%endmacro

extern loadNewIDT

extern picMapInterrupts
%macro APicMapInterrupts 1
	mov ax, %1
	call picMapInterrupts
%endmacro

extern startAllAPs
%macro AStartAllAPs 1
	mov eax, %1
	call startAllAPs
%endmacro

extern InitialiseAPICModule

extern picRemapIRQ
