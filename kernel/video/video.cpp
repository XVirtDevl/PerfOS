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

Video &Video::operator<<(void *ptr)
{
	char x = 60;
	m_currAddr[0] = (m_textAttributes<<8)|'0';
	m_currAddr[1] = (m_textAttributes<<8)|'x';
	m_currAddr+=2;

	for(;;)
	{
		unsigned char val =  ((unsigned long)ptr>>x) & 0xF;

		if( val > 9 )
			val+=55;
		else
			val+=48;

		*m_currAddr = (m_textAttributes<<8)|val;
		m_currAddr++;
		
		x-=4;
		if( x < 0 )
			return *this;
	}

	return *this;
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

#define MAXINTLENGTH 10
Video &Video::operator<<(unsigned int val )
{
	char outputBuffer[MAXINTLENGTH+1];
	outputBuffer[MAXINTLENGTH] = '\0';

	int i;
	for( i = MAXINTLENGTH-1;;i--)
	{
		outputBuffer[i] = val%10+48;
		val = val/10;
		if( val == 0 )
		{
			break;
		}
	}
	
	return *this<<&outputBuffer[i];
}

void Video::SetForegroundAttributes( ConsoleColors newCol )
{
	m_textAttributes&=0xF0;
	m_textAttributes|=newCol;
}

void Video::SetBackgroundAttributes( ConsoleColors newCol )
{
	m_textAttributes &= 0xF;
	m_textAttributes |= (newCol<<4);
}
