struc multiboot
	.flags resd 1
	.mem_lower resd 1
	.mem_upper resd 1
	.bootdevice resd 1
	.commandline resd 1
	.mod_count resd 1
	.mod_addr resd 1
	.sys resd 1
	.mmap_length resd 1
	.mmap_addr resd 1
	.gdtr_addr resd 1
	.idtr_addr resd 1
	.entry_pt resd 1
endstruc


%define MultibootStrucAddr 0x500
