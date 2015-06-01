%include "metaprogramming.inc"

GUARDED_INCLUDE GUARDED_EXPORT_GRAPHIC_VBE, "graphic.inc" 

align 8
PolymorphicFunctionList:
	times GraphicFunctionality_size db 0 


global InitialiseVBEDriver
; edi = vbe mode info
InitialiseVBEDriver:
	ret



video_mode_desc:
	.bytes_per_scanline dq 0
	.x_resolution_pixel dq 0
	.y_resolution_pixel dq 0
	.lfb_address dq 0
	.bits_per_pixel dq 0

