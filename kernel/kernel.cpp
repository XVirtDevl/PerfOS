#include "video.hpp"

extern "C" int main();

int main()
{
	Video *vid = Video::GetInstance();
	
	vid->ClearScreen();

	*vid<<"Hallo Welt!\n Next Line!"<<102340;
	vid->SetForegroundAttributes( LIGHTBLUE );
	*vid<<"\nRed Color";
	vid->SetBackgroundAttributes( WHITE );
	*vid<<"Jolo own kernel!!!!";
	return 0;
}
