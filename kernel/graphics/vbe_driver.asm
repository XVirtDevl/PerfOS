%include "meta/metaprogramming.inc"

GUARDED_INCLUDE GUARDED_EXPORT_GRAPHIC_VBE, "graphic.inc" 

align 8
PolymorphicFunctionList:
	times GraphicFunctionality_size db 0 

global DrawChar
; al = char
DrawChar:
	mov edi, dword[ driver_settings.draw_address ]
	add dword[ driver_settings.draw_address ], 8

	shl rax, 3
	mov rsi, Font8X8BIOS
	add rsi, rax
	mov r8, rsi
	add r8, 8
	

	mov rbx, 0x0909090909090909
	xor rcx, rcx	
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

		cmp rsi, r8
		jz .done
		jmp .drawLoop
	.done:
		ret

BreakLine:
	mov eax, dword[ driver_settings.draw_address ]
	mov ebx, dword[ video_mode_desc.bytes_per_scanline ]
	shl ebx, 3
	mov edi, eax
	sub eax, dword[ video_mode_desc.lfb_address ]
	add edi, ebx

	xor edx, edx
	div ebx

	not edx
	add edx, 1
	add edi, edx
	mov dword[ driver_settings.draw_address ], edi
	ret

	
	
	
global DrawString
;esi = string
DrawString:
	xor eax, eax

	.looped:
		mov al, byte[ esi ]
	
		or al, al
		jz .done
	
		cmp al, 0xA
		jz .newline

		push rsi
		call DrawChar
		pop rsi
		add esi, 1
		jmp .looped

	.newline:
		add esi, 1
		call BreakLine
		jmp .looped

	.done:
		ret
	

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
	movzx esi, word[ edi + 0x10 ]
	
	mov dword[ video_mode_desc.lfb_address ], eax
	add eax, esi	
	mov word[ video_mode_desc.bytes_per_scanline ], si
	mov word[ video_mode_desc.x_resolution_pixel ], bx
	mov word[ video_mode_desc.y_resolution_pixel ], cx
	mov word[ video_mode_desc.bits_per_pixel ], dx
	mov dword[ driver_settings.draw_address ], eax

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
		jnz .BuildTable

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
	.draw_address dq 0

video_mode_desc:
	.bytes_per_scanline dq 0
	.x_resolution_pixel dq 0
	.y_resolution_pixel dq 0
	.lfb_address dq 0
	.bits_per_pixel dq 0
BitsPerPixel8Mask resq 256
