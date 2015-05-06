#ifndef _MULTIBOOT_HPP_
#define _MULTIBOOT_HPP_

#define MEM_UPPER_LOWER_PRESENT 1
#define BOOTDEVICE_PRESENT 2
#define CMDLINE_PRESENT 4
#define MOD_COUNT_ADDR_PRESENT 8
#define SYMS_PRESENT 16|32
#define MEM_MAP_LENGTH_ADDR_PRESENT 64
#define DRIVE_LENGTH_ADDR_PRESENT 128
#define CONFIG_TABLE_PRESENT 256
#define BOOTLOADER_NAME_PRESENT 512
#define APM_TABLE_PRESENT 1024

struct multibootstruc
{
	int flags;
	int mem_low;
 	int mem_high;
	int bootdev;
	int cmdLine;
	int modCnt;
	int modAddr;
	int syms;	
	int memmap_length;
	int memmap_addr;
	int drives_length;
	int drives_addr;
	int config_table;
	int bootloader_name;
	int apm_table;
	
};


#endif
