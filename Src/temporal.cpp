

#include "temporal_root.i"


static const char* WelcomeMsg = R"(teMpOwAl resurtch!!

Steve is about to divulge magical temporal randomness from the brain of your device.
)";


Ooof int ParseWarmup(StringVec& Args) {
	if (Args.size() >= 3) {
		auto S = Args[2];
		return Num(S);
	}
	
	return 1;
}


static int ListAction (BookHitter* B, StringVec& Args) {
	if (Args.size() < 2) return ArgError;
	const int NumBytes = 16 * 1024; 
	ByteArray D(NumBytes, 0);
	
	auto& Conf = *bh_config(B); 

	Conf.Log = true;
	B->SetChannel( GetNum(Args, 1) );
	if (errno) return errno;
	Conf.DontSortRetro = true;
	Conf.AutoReScore = 0;
//	Conf.WarmupMul = 1;//ParseWarmup(Args);

	puts(WelcomeMsg);

	auto Result = bh_hitbooks(B, &D[0], 1);
	auto html = B->HTML("temporal.html",  "Randomness Test");
//	printf(":: Warmupmul: %i ::\n", Conf.WarmupMul);
	
	for_(16) {
		if (Result->Err) break;
		B->DebugLoopCount = i + 1;
		Result = bh_hitbooks(B, &D[0], NumBytes);
		
		if (i == 0)
			ReportStuff(Result);

		auto App = B->App;
		auto s = App->Name();
		printf( ":: %i:  %s (", i + 1,  s.c_str() );
		printf( "%.3fs) ::\n",  Result->GenerateTime + Result->ProcessTime );
		html->WriteOne(App);
	}
	
	html->Finish();
	bh_logfiles(B);

	return Result->Err;
}


static int ReadMemoryAction (BookHitter* B, u8* Addr, u32 Len, std::ostream& ofs) {
	GenApproach R = {};

	FullHistogramDetect(R, Addr, Len);
	
	
	int F = R.Stats.FailedIndexes;
	ofs << ((F) ? " ❌" : "");
	for_ (5) {
		ofs << "\n" + ScoreNames[i].substr(0,4) + ": ";
		ofs << std::fixed << std::setprecision(3) << R[i];
		ofs << (((1<<i) & F) ? " ❌" : "");
	}
	ofs << "\n";
	
	return 0;
}


static int ReadAction (BookHitter* B, StringVec& Args) {
	if (Args.size() < 2) return ArgError;
	
	printf("Non-randomness in file: %s (lower is better)\n", Args[1].c_str());
	auto FileData = ReadFile(Args[1], 100*1024*1024);
	if (errno) {
		printf("Can't read: %s (%s)\n", Args[1].c_str(), strerror(errno));
		return ArgError;
	}
		
	u8* Addr = (u8*)FileData.c_str();
	u32 Len  = (u32)FileData.length();

	return ReadMemoryAction( B, Addr, Len, std::cout );
}

// temporal dump   1    1024000 file.rnd

int DumpAction (BookHitter* B, StringVec& Args, bool Hex) {
	if (Args.size() < 4)
		return ArgError;
	
	bh_config(B)->Log = -1; // no log even debug
	B->SetChannel(GetNum(Args,1));
	
	int          Remain   = ParseLength(Args[2]);
	if (!Remain) return errno;
	string       FileOut  = Args[3];
	FILE*        Dest     = CmdArgFile(FileOut, stdout);
	if (!Dest)   return errno;

	auto TStart = Now();
	u32 Written = 0;
	int OldSeconds = 0;
	int DSize = 64 * 1024;
	ByteArray D(DSize, 0);

	auto Chan = B->ViewChannel();
	auto ChanName = Chan->Name();
 
	if (Dest != stdout)
		printf( "Steve is sending %s randomness to: %s\n", ChanName.c_str(), FileOut.c_str() );
	
	while (Remain > 0) {
		u32 This = min(DSize, Remain);
		bh_stats* Result = bh_hitbooks(B, &D[0], This);
		if (Result->Err) return Result->Err;
		if (Hex)
			fhexwrite(&D[0], This, Dest);
		  else
			fwrite(&D[0], 1, This, Dest);

		Remain  -= This;
		Written += This;

		if (Dest != stdout) {
			int Seconds = floorf(ChronoLength(TStart));
			if ((Seconds/5) > (OldSeconds/5) or !Remain) {
				OldSeconds = Seconds;
				printf("%.1fKB in %is\n", ((float)(Written))/1024, Seconds);
			} 
		}
	}

	if (Hex) fputc('\n', Dest);
	

	fclose(Dest);
	return 0;
}


int main (int argc, const char* argv[]) {
	auto RestoreDir = getcwd(0, 0);
	auto Args = ArgArray(argc, argv);
	int Err = ArgError;

	auto B = bh_create();
	if (Args.size() <= 0)
		Err = ArgError; 
	  
	  else if ( matchi(Args[0], "dump") )
		Err = DumpAction(B, Args, false);
	  
	  else if ( matchi(Args[0], "hexdump") )
		Err = DumpAction(B, Args, true);
		
	  else if ( matchi(Args[0], "list") )
		Err = ListAction(B, Args);
	  
	  else if ( matchi(Args[0], "read") )
		Err = ReadAction(B, Args);

	bh_free(B);

	if (Err == ArgError)
		printf(
"Usage: temporal dump     (-50 to 50) (1KB to 1000MB) (file.txt)\n"
"       temporal hexdump  (-50 to 50) (1KB to 1000MB) (file.txt)\n""  (or)\n"
"       temporal list     (-50 to 50)\n\n"
"       temporal read     (file.txt)\n\n"
"  About: http://randonauts.com/s/temporal \n");

	printf("\n");
	chdir(RestoreDir);
	return Err;
}

