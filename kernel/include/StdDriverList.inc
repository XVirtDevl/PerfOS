%ifndef _STANDARD_KERNEL_DRIVERS_INC_
%define _STANDARD_KERNEL_DRIVERS_INC_

	%ifndef _STDKERNEL_EXPORT_
	%define _STDKERNEL_EXPORT_
		extern RegisteredDrivers
	%endif

struc RegisteredDriversStruct
	.graphic resq 1
endstruc


%endif
