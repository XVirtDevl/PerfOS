%include "meta/metaprogramming.inc"

GUARDED_INCLUDE GUARDED_EXPORT_GRAPHIC_VBE, "graphic.inc" 

align 8
PolymorphicFunctionList:
	times GraphicFunctionality_size db 0 


global DrawChar
; al = char
DrawChar:
	mov edi, dword[ video_mode_desc.lfb_address ]
	add edi, dword[ video_mode_desc.bytes_per_scanline ]
	add edi, dword[ video_mode_desc.bytes_per_scanline ]
	add edi, 400
	mov rsi, Font8X8BIOS + 67 *8

	mov rbx, 0x0909090909090909
	mov rcx, 0x0F0F0F0F0F0F0F0F
	
	.drawLoop:
		push rbx
		push rcx
		movzx eax, byte[ rsi ]
		shl eax, 3
		mov rdx, qword[ eax + BitsPerPixel8Mask ]
		and rbx, rdx
		not rdx
		and rcx, rdx

		or rbx, rcx
		mov qword[ rdi ], rbx
		add rsi, 1
		add rdi, qword[ video_mode_desc.bytes_per_scanline ]
		pop rcx
		pop rbx

		cmp rsi, Font8X8BIOS + 68*8
		jz .done
		jmp .drawLoop
	.done:
		jmp $
	

global InitialiseVBEDriver
; edi = vbe mode info
InitialiseVBEDriver:
	push rbx
	push rsi
	push rax
	push rcx
	push rdx

	mov eax, dword[ edi + 0x28 ]		;
	mov bx, word[ edi + 0x12 ]		; X Resolution
	mov cx, word[ edi + 0x14 ]		; Y Resolution
	movzx dx, byte[ edi + 0x19 ]
	mov si, word[ edi + 0x10 ]
	
	mov dword[ video_mode_desc.lfb_address ], eax	
	mov word[ video_mode_desc.bytes_per_scanline ], si
	mov word[ video_mode_desc.x_resolution_pixel ], bx
	mov word[ video_mode_desc.y_resolution_pixel ], cx
	mov word[ video_mode_desc.bits_per_pixel ], dx

	xor cl, cl
	xor rax, rax
	mov rdi, BitsPerPixel8Mask
	mov rdx, 0xFF
	mov bl, 1
	.BuildTable:
		test cl, bl
		jz .test2
		or rax, rdx
	.test2:
		shl rdx, 8
		shl bl, 1
		jnz .BuildTable
	.next:
		mov qword[ rdi ], rax
		add rdi, 8
		xor eax, eax
		mov rdx, 0xFF
		mov bl, 1
		add cl, 1
		jno .BuildTable

	pop rdx
	pop rcx
	pop rax
	pop rsi
	pop rbx
	ret

global SetVBEDriverAsGraphicDriver
SetVBEDriverAsGraphicDriver:
	push rdi
	mov rdi, PolymorphicFunctionList
	;mov qword[ RegisteredDrivers + RegisteredDriverStruct.graphic ], rdi
	pop rdi
	ret 


driver_settings:
	.font_size_x dq 8
	.font_size_y dq 8
video_mode_desc:
	.bytes_per_scanline dq 0
	.x_resolution_pixel dq 0
	.y_resolution_pixel dq 0
	.lfb_address dq 0
	.bits_per_pixel dq 0
section .bss
	BitsPerPixel8Mask resq 256
