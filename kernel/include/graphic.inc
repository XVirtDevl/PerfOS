%ifndef _GRAPHIC_DRIVER_INCLUDE_
%define _GRAPHIC_DRIVER_INCLUDE_

%include "StdDriverList.inc"

struc GraphicFunctionality
	.getXResolutionInPixel resq 1
	.getYResolutionInPixel resq 1
	.getXResolutionInChars resq 1
	.getYResolutionInChars resq 1
endstruc

%macro GetXResolutionInPixel 0
	mov rbx, qword[ RegisteredDrivers + RegisteredDriverStruct.graphic ]
	call qword[ rbx + GraphicFunctionality.getXResolutionInPixel ] 
%endmacro


	%ifndef GUARED_EXPORT_GRAPHIC_VBE
	%define GUARED_EXPORT_GRAPHIC_VBE
		extern InitialiseVBEDriver
	%endif
	
	%ifndef GUARED_EXPORT_GRAPHIC_VGA
	%define GUARED_EXPORT_GRAPHIC_VGA
		extern InitialiseVGADriver
		extern Font8X8BIOS
	%endif
	



%endif
