%ifndef _GRAPHIC_DRIVER_INCLUDE_
%define _GRAPHIC_DRIVER_INCLUDE_

%include "StdDriverList.inc"
%include "vbe_driver.inc"

struc GraphicFunctionality
	.getXResolutionInPixel resq 1
	.getYResolutionInPixel resq 1
	.getXResolutionInChars resq 1
	.getYResolutionInChars resq 1
	.setForegroundAttributes resq 1
	.setBackgroundAttributes resq 1
endstruc

%macro GetXResolutionInPixel 0
	mov rbx, qword[ RegisteredDrivers + RegisteredDriversStruct.graphic ]
	call qword[ rbx + GraphicFunctionality.getXResolutionInPixel ] 
%endmacro

%macro GetYResolutionInPixel 0
	mov rbx, qword[ RegisteredDrivers + RegisteredDriversStruct.graphic ]
	call qword[ rbx + GraphicFunctionality.getYResolutionInPixel ]
%endmacro

%macro GetXResolutionInChars 0
	mov rbx, qword[ RegisteredDrivers + RegisteredDriversStruct.graphic ]
	call qword[ rbx + GraphicFunctionality.getXResolutionInChars ]
%endmacro

%macro GetYResolutionInChars 0
	mov rbx, qword[ RegisteredDrivers + RegisteredDriversStruct.graphic ]
	call qword[ rbx + GraphicFunctionality.getYResolutionInChars ]
%endmacro




	%ifndef GUARDED_EXPORT_GRAPHIC_VBE
	%define GUARDED_EXPORT_GRAPHIC_VBE
		extern InitialiseVBEDriver
		extern SetVBEDriverAsGraphicDriver
	%endif
	
	%ifndef GUARDED_EXPORT_GRAPHIC_VGA
	%define GUARDED_EXPORT_GRAPHIC_VGA
		extern InitialiseVGADriver
		extern Font8X8BIOS
	%endif
	



%endif
