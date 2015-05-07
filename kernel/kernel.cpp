#include "video.hpp"
#include "multiboot.hpp"
#include "memory.hpp"

extern "C" int kernel(multibootstruc *mbs);

int kernel(multibootstruc *mbs)
{
	Video *vid = Video::GetInstance();

	vid->ClearScreen();

	*vid<<"Hallo Welt!\n Next Line!"<<102340;
	vid->SetForegroundAttributes( RED );
	*vid<<"\nRed Color";
	if( mbs->flags & MEM_MAP_LENGTH_ADDR_PRESENT )
		*vid<<"\nMemory Map present!";
	else
		*vid<<"\nFatal error no memory map available";

	PhysMemManager man1;
	man1.Initialise( (MemMapEntry*)mbs->memmap_addr, mbs->memmap_length );
	
	return 0;
}
