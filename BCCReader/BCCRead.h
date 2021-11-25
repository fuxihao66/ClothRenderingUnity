#ifdef BCCFILEREADER_EXPORTS
#define BCCREAD_API __declspec(dllexport)
#else
#define BCCREAD_API __declspec(dllimport)
#endif

extern "C" {

	BCCREAD_API int ReadBCCFile(const char* bccFilePath, unsigned char* vertexBuffer, unsigned int* indicesBuffer, unsigned int& vertexNum, unsigned int& indexNum);

}

