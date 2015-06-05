%include "meta/metaprogramming.inc"

GUARDED_INCLUDE GUARDED_EXPORT_GRAPHIC_VBE, "graphic.inc" 

%define DISABLE_DRIVER 1

align 16
PolymorphicFunctionList:
	times GraphicFunctionality_size db 0 


global InitialiseVBEDriver
; edi = vbe mode info
InitialiseVBEDriver:
	push rbx
	push rsi
	push rcx
	push rdx

	mov al, byte[ edi + 0x1B ]

	cmp al, 0x6
	jnz .unsupported_color

	mov esi, edi
	mov ecx, (video_mode_desc_end - video_mode_desc)
	mov edi, video_mode_desc
	rep movsb

	mov al, byte[ video_mode_desc + vbe_mode_info_block.bits_per_pixel ]

	cmp al, 15
	jz .unsupported_color

	cmp al, 8
	jz .unsupported_color

	cmp al, 4
	jz .unsupported_color

	xor cl, cl
	xor rax, rax
	mov rdi, BitsPerPixel8Mask
	mov rdx, 0xFFFF
	mov bl, 1
	xor rsi, rsi
	.BuildTable:
		test cl, bl
		jz .test2
		or rax, rdx
	.test2:
		shl rdx, 16
		jnz .continue
		mov rdx, 0xFFFF
		mov rsi, rax
		xor rax, rax
	.continue:
		shl bl, 1
		jnz .BuildTable
	.next:
		mov qword[ rdi ], rsi
		mov qword[ rdi + 8 ], rax
		add rdi, 16
		xor eax, eax
		mov rdx, 0xFFFF
		mov bl, 1
		add cl, 1
		jnz .BuildTable

	mov ecx, 8
	mov edx, 8
	call SetFont

	mov rdi, VBEGetXResolutionInPixels
	mov rdx, VBEGetYResolutionInPixels
	mov rcx, VBEGetXResolutionInChars
	mov rax, VBEGetYResolutionInChars
	mov qword[ PolymorphicFunctionList + GraphicFunctionality.getXResolutionInPixel ], rdi
	mov qword[ PolymorphicFunctionList + GraphicFunctionality.getYResolutionInPixel ], rdx
	mov qword[ PolymorphicFunctionList + GraphicFunctionality.getYResolutionInChars ], rax
	mov qword[ PolymorphicFunctionList + GraphicFunctionality.getXResolutionInChars ], rcx

	pop rdx
	pop rcx
	pop rsi
	pop rbx
	xor al, al
	ret

	.unsupported_color:
		pop rdx
		pop rcx
		pop rax
		pop rsi
		pop rbx
		mov al, 1
		mov byte[ output_settings.attributes ], DISABLE_DRIVER
		ret


VBESetBackgroundColor:
	push rsi
	mov esi, output_settings.background_attributes
	jmp VBESetForegroundColor.func_entry

;edi = color 32 bit
VBESetForegroundColor:
	push rsi
	mov esi, output_settings.foreground_attributes

	.func_entry:
	push rax
	push rbx
	push rcx
	push rdx

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx

	mov ax, di	; RGB al = Blue value ah = Green value
	mov bl, ah
	mov edx, edi
	xor ah, ah
	shr edx, 16	; RGB dl = red value

	mov cl, 8
	sub cl, byte[ video_mode_desc + vbe_mode_info_block.blue_mask_size ]

	shr al, cl

	mov cl, 8
	sub cl, byte[ video_mode_desc + vbe_mode_info_block.green_mask_size ]

	shr bl, cl

	mov cl, 8
	sub cl, byte[ video_mode_desc + vbe_mode_info_block.red_mask_size ]

	shr dl, cl

	mov cl, byte[ video_mode_desc + vbe_mode_info_block.blue_field_pos ]
	shl eax, cl

	mov cl, byte[ video_mode_desc + vbe_mode_info_block.green_field_pos ]
	shl ebx, cl

	mov cl, byte[ video_mode_desc + vbe_mode_info_block.red_field_pos ]
	shl edx, cl
	or eax, ebx
	or eax, edx					;clamped color in eax

	cmp byte[ video_mode_desc + vbe_mode_info_block.bits_per_pixel ], 24
	jz .odd24BitColor

	cmp byte[ video_mode_desc + vbe_mode_info_block.bits_per_pixel ], 32
	jz .32BitColor

	mov bx, ax

	shl eax, 16
	mov ax, bx		; eax = hi = 16 Bit color lo = 16 Bit Color

	shl rax, 16
	mov ax, bx

	shl rax, 16
	mov ax, bx

	mov qword[ esi ], rax
 

	.odd24BitColor:
		mov dword[ esi ], eax
		jmp .endFunc
	.32BitColor:
		mov dword[ esi ], eax
		mov dword[ esi + 4], eax

	.endFunc:


	pop rdx
	pop rcx
	pop rbx
	pop rax
	pop rsi

	ret

SetFont:
	ret

VBEGetXResolutionInPixels:
	mov eax, dword[ video_mode_desc + vbe_mode_info_block.xresolution ]
	ret

VBEGetYResolutionInPixels:
	mov eax, dword[ video_mode_desc + vbe_mode_info_block.yresolution ]
	ret

VBEGetXResolutionInChars:
;	mov eax, dword[ driver_settings.x_resolution_chars ]
	ret

VBEGetYResolutionInChars:
;	mov eax, dword[ driver_settings.y_resolution_chars ]
	ret

VBESetForegroundColor16:
	

global SetVBEDriverAsGraphicDriver
SetVBEDriverAsGraphicDriver:
	cmp byte[ output_settings.attributes ], DISABLE_DRIVER
	jz .failed

	push rdi
	mov rdi, PolymorphicFunctionList
	mov qword[ RegisteredDrivers + RegisteredDriversStruct.graphic ], rdi
	pop rdi

	xor eax, eax
	ret

	.failed:
		mov eax, 1
		ret 


output_settings:
	.attributes dq 0
	.foreground_attributes dq 0
	.background_attributes dq 0
	.x_res_in_chars dq 0
	.y_res_in_chars dq 0
	.output_start_address dq 0
	.output_write_address dq 0
	.output_read_address dq 0

section .bss
BitsPerPixel8Mask resq 256*2
video_mode_desc:
	resb vbe_mode_info_block_size
video_mode_desc_end:
