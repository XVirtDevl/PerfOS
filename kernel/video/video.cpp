#include "video.hpp"

Video Video::m_inst;
void Video::ClearScreen()
{
	unsigned long *base = (unsigned long*)m_baseAddr;
	unsigned long newVal = (0x20<<16)|(m_textAttributes<<24)|0x20|(m_textAttributes<<8);
	for( int i = 0; i < 40*25; i++ )
		base[i] = newVal;

	m_currAddr = m_baseAddr;
}

void Video::Initialise( short *baseAddress )
{
	m_baseAddr = baseAddress;	
	m_currAddr = baseAddress;
	m_textAttributes = 0x0F;
	m_lineLengthInBytes = 160;
}

Video *Video::GetInstance()
{
	static bool initialised = false;
	if( !initialised )
	{
		m_inst.Initialise((short*)0xb8000);
		initialised = true;
	}
	return &m_inst;
}

Video &Video::operator<<(const char *str)
{
	for(int i =0;;i++)
	{
		if( str[i] == 0 )
			return *this;
		if( str[i] == '\n' )
		{
			m_currAddr += (m_lineLengthInBytes-((unsigned long)m_currAddr-(unsigned long)m_baseAddr)%m_lineLengthInBytes)/2;
			continue;
		}
		
		*m_currAddr = (m_textAttributes<<8)|str[i];
		m_currAddr++;
	}
}

void Video::SetForegroundAttributes( ConsoleColors &newCol )
{
	m_textAttributes&=0xF0;
	m_textAttributes|=newCol;
}

void Video::SetBackgroundAttributes( ConsoleColors &newCol )
{
	m_textAttributes &= 0xF;
	m_textAttributes |= (newCol<<4);
}
