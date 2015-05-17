struc multiboot
	.flags resd 1
	.mem_lower resd 1
	.mem_upper resd 1
	.bootdevice resd 1
	.commandline resd 1
	.mod_count resd 1
	.mod_addr resd 1
	.sys resd 4
	.mmap_length resd 1
	.mmap_addr resd 1
	.gdtr_addr resd 1
	.idtr_addr resd 1
	.entry_pt resd 1
endstruc


%define MultibootStrucAddr 0x500 ;Address at which the multiootstructure will be relocated to or written by the self written bootloader to
%define MemMapAddr 0x600 ;Relocates the MemMap to address 0x600 or if the bootloader from PerfOS is used create it at that address
