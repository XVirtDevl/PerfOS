#include "video.hpp"

extern "C" int main();

int main()
{
	Video *vid = Video::GetInstance();
	
	vid->ClearScreen();

	*vid<<"Hallo Welt!\n Next Line!";

	return 0;
}
