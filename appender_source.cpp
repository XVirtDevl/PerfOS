#include <iostream>
#include <fstream>


using namespace std;


int main(int count, char **argv)
{

	unsigned char Padding[200000];
	for( int i = 0; i < 1024; i++ )
		Padding[i] = 0x80;
	unsigned long fileLength;
	ifstream is( argv[1], ios::binary | ios::ate );
	fileLength = is.tellg();
	is.close();



	unsigned long truncate = 512-(fileLength%512);
	unsigned long writeSize = truncate+1024;

	ofstream os( argv[1], ios::app | ios::binary );
	os.write( (char*)Padding, writeSize );
	os.close();

	ifstream rd( argv[2], ios::binary );
	rd.read( (char*)Padding, fileLength+writeSize );
	*(unsigned long*)(((unsigned long)Padding)+500) = (fileLength+truncate)/512;
	rd.close();

	ofstream wr( argv[2], ios::binary );
	wr.write( (const char*)Padding, fileLength+writeSize );
	wr.close();
	cout<<"Appended "<<writeSize<<" Bytes to file: "<<argv[2]<<" to truncate the file size to a multiple of 512!"<<endl;
	cout<<"Wrote byte code change to load "<<(fileLength+truncate)/512<<" sectors from within the mbr!"<<endl;

	return 0;
}

