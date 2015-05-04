

extern "C" int main();

int main()
{
	short *byte =(short*)0xb8000;
	for( int i = 0; i < 80*25;i++)
	{
		byte[i] = (0x0F<<8)|(0x20);	
	}

	byte = (short*)(0xb8000);
	*byte = (0x04<<8)|('H');
	return 0;
}
