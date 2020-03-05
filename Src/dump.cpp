


#include "temporal_root.i"



static int SplitUnit(string L) {
	for_(L.size())
		if (L[i] < '0' or L[i] > '9')
			return i;
	return (int)L.size();
}


static int ParseLength (string L) {
	int mul = 0;
	int spl = SplitUnit(L);
	string U = L.substr(spl, (int)L.size());
	int UL = (int)U.size() - 1;
	auto Last = U[UL];
	if (Last == 'b' or Last == 'B')
		U = U.substr(0, UL);

	if (U == "")
		mul = 1;
	  else if (U=="k" or U == "K")
		mul = 1024;
	  else if (U=="m" or U == "M")
		mul = 1024 * 1024;
	  else
		std::cerr << "Can't use unit: " << U;

	if (mul) {
		string Amount = L.substr(0, spl);
		if (Amount.size())
			return atoi(Amount.c_str()) * mul;
	}

	errno = -1;
	return 0;
}


static FILE* OofFile (string FileOut) {
	if (FileOut == "")  return 0;
	if (FileOut == "-") return stdout;

	auto Dest = fopen(FileOut.c_str(), "w");
	if (Dest) return Dest;

	std::cerr << "Can't open: " << FileOut;
	return 0;
}



// temporal 1    1024000 file.rnd 
// temporal chan size    fileout

int main (int argc, const char* argv[]) {
	if (argc < 4) {
		printf(
"Usage: %s Channel FileSize FileName\n"
"eg: %s 1   32KB  steve.rnd\n\n", argv[0], argv[0]);
		return 0;
	}
	
	auto F = bh_create();
	bh_config(F)->Log = -1; // no log even debug
	bh_config(F)->Channel = atoi(argv[1]);
	int          Remain   = ParseLength(argv[2]);
	string       FileOut  = argv[3];
	if (!Remain) return errno;
	FILE*        Dest     = OofFile(FileOut);
	if (!Dest)   return errno;

	auto TStart = Now();
	u32 Written = 0;
	int OldSeconds = 0;
	int DSize = 256 * 1024;
	ByteArray D(DSize, 0);
	
	printf("Steve is writing randomness to: %s\n", FileOut.c_str());
	
	while (Remain > 0) {
		bh_stats* Result = bh_hitbooks(F, &D[0], DSize);
		if (Result->Err) return Result->Err;
		u32 This = min(DSize, Remain);
		fwrite(&D[0], 1, This, Dest);
		Remain  -= This;
		Written += This;
		
		int Seconds = floorf(ChronoLength(TStart));
		if ((Seconds/5) > (OldSeconds/5) or !Remain) {
			OldSeconds = Seconds;
			printf("%.1fKB in %is\n", ((float)(Written))/1024, Seconds);
		} 
	}

	fclose(Dest);
	bh_free(F);
	return 0;
}

