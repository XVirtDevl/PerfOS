%define BOOTUP_PML4_ADDR 0x300000

extern BlockMemory
%macro PMBlockMemory 2
	mov rdi, %1
	mov rcx, %2
	call BlockMemory
%endmacro

extern InitialisePhysMem

extern AllocMemory
%macro PMAllocMemory 2
	mov rax, %1
	mov rsi, %2
	call AllocMemory
%endmacro

extern AllocMemoryAligned
%macro PMAllocMemoryAligned 3
	mov rax, %1
	mov rsi, %2	
	mov rcx, %3
	call AllocMemoryAligned
%endmacro

extern FreeMemory
%macro PMFreeMemory 1
	mov rax, %1
	call FreeMemory
%endmacro

extern DebugMemoryAllocation
extern PrintAllHeads
