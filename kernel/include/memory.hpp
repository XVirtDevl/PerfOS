#ifndef _MEMORY_HPP_
#define _MEMORY_HPP_
#include "video.hpp"

struct MemMapEntry
{
	void *m_baseAddr;
	unsigned long m_size;
	unsigned int m_type;
	unsigned int m_acpi30info;
};


class PhysMemManager
{

	public:
		void Initialise( MemMapEntry *firstEntry, unsigned int memmapLength );
};


#endif
