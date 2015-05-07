#include "memory.hpp"

const char *MemType[] = { "Free Memory", "Reserved memory - unusable", "ACPI reclaimable memory", "ACPI NVS memory", "bad memory" };

void PhysMemManager::Initialise( MemMapEntry *firstEntry, unsigned int memmapsize )
{

	Video *vid = Video::GetInstance();
	*vid<<"\nBase Address       | Size               | Type\n";
	for( ;memmapsize > 0; )
	{
		*vid<<firstEntry->m_baseAddr<<" | "<<(void*)firstEntry->m_size<<" | "<<MemType[firstEntry->m_type-1]<<"\n";
		firstEntry++;
		memmapsize-=24;
	}
}
