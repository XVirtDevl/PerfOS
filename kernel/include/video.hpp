#ifndef _VIDEO_HPP_
#define _VIDEO_HPP_

enum ConsoleColors
{	
	BLACK = 0,
	BLUE = 1,
	GREEN = 2,
	TURQUIS = 3,
	RED = 4,
	MAGENTA = 5,
	BROWN = 6,
	GREY = 7,
	LIGHTBLACK = 8,
	LIGHTBLUE = 9,
	LIGHTGREEN = 10,
	LIGHTTURQUIS = 11,
	LIGHTRED = 12,
	LIGHTMAGENTA = 13,
	LIGHTBROWN = 14,
	WHITE = 15
};


class Video
{
	private:
		static Video m_inst;
		Video(){}

		short *m_baseAddr;
		unsigned char m_textAttributes;
		short *m_currAddr;
		unsigned long m_lineLengthInBytes;
		
		void Initialise( short *baseAddress );	

	public:
		static Video *GetInstance();
		void ClearScreen();
		void SetForegroundAttributes( ConsoleColors &newCol );
		void SetBackgroundAttributes( ConsoleColors &newCol );
		Video &operator<<(const char *str);
};

#endif
