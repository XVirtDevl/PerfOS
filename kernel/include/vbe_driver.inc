%ifndef _VBE_DRIVER_INCLUDE_
%define _VBE_DRIVER_INCLUDE_

struc vbe_mode_info_block
	.mode_attributes resw 1
	.wina_attributes resb 1
	.winb_attributes resb 1
	.win_granularity resw 1
	.win_size resw 1
	.wina_seg resw 1
	.winb_seg resw 1
	.win_func_ptr resd 1
	.bytes_per_scanline resw 1
	.xresolution resw 1
	.yresolution resw 1
	.xcharsize resb 1
	.ycharsize resb 1
	.num_of_planes resb 1
	.bits_per_pixel resb 1
	.num_of_banks resb 1
	.memory_model resb 1
	.bank_size resb 1
	.number_of_image_pages resb 1
	.reserved resb 1
	.red_mask_size resb 1
	.red_field_pos resb 1
	.green_mask_size resb 1
	.green_field_pos resb 1
	.blue_mask_size resb 1
	.blue_field_pos resb 1
	.rsvd_mask_size resb 1
	.rsvd_field_pos resb 1
	.direct_color_mode_info resb 1
	.lfb_address resd 1
	.offscreen_mem_offset resd 1
	.offscreen_mem_size resw 1
endstruc

%endif
