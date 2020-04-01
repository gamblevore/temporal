

#define  __SHELL_TOOL__
#include "temporal_root.i"


static const char* WelcomeMsg = R"(teMpOwAl resurtch!!

Steve is about to divulge magical temporal randomness from the brain of your device.
)";

string OrigPath;

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
//	Conf.DontSortRetro = true; // better to sort?
	Conf.AutoReScore = 0;
	
	puts(WelcomeMsg);

	auto Result = bh_hitbooks(B, &D[0], 1);
	auto html = B->HTML("temporal.html",  "Randomness Test");

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


static void ReportStats(GenApproach &R,  string Name,  std::ostream &ofs) {
	if (Name.length())
		printf( "Non-randomness in: %s (lower is better)\n", Name.c_str() );

	int F = R.Stats.FailedIndexes;
	for_ (5) {
		ofs << "\t";
		ofs << ScoreNames[i].substr(0,4) + ": ";
		ofs << std::fixed << std::setprecision(3) << R[i];
		ofs << (((1<<i) & F) ? " ❌" : "");
		ofs << "\n";
	}
	ofs << "\n";
}


static int ReadMemoryAction (GenApproach& R, u8* Addr, u32 Len, std::ostream& ofs, string Name) {
	if (AllHex(Addr, Len))
		Len = HexCleanup(Addr, Len);
	FullRandomnessDetect(R, Addr, Len);
	ReportStats(R, Name, ofs);
	return 0;
}


static int ReadStrAction (GenApproach& R, string S, std::ostream& ofs, string Name) {
	u8* Addr = (u8*)S.c_str();
	u32 Len  = (u32)S.length();
	return ReadMemoryAction( R, Addr, Len, ofs, Name );
}



static int ViewAction (BookHitter* B, StringVec& Args, bool Visualise) {
	if (Args.size() < 2) return ArgError;
	auto Path = ResolvePath(Args[1]);
	if (Path == "-") {
		; // 
	} else if (!fisdir(Path.c_str())) {
		fprintf(stderr, "Expected a directory at: %s\n", Path.c_str());
		return ArgError;
	}

	B->ExternalReports();
	ApproachVec Reports;
	
	if (Path == "-") {
		auto R = B->ExternalGen("stdin", Visualise);
		Reports.push_back(R);
		string StdIn = (Args.size() >= 3) ? Args[2] : ReadStdin();
		ReadStrAction( *R, StdIn, std::cout, "stdin" );
	} else {
		DirReader D = Path;
		while (D.Next()) {
			auto Item = D.Name();
			auto FullPath = Path + "/" + Item;
			auto FileData = ReadFile(FullPath, 0x7fffFFFF);
			if (!FileData.length()) continue;
			
			auto R = B->ExternalGen(Item, Visualise);
			Reports.push_back(R);
			ReadStrAction( *R, FileData, std::cout, Item );
		}
	}
	
	ApproachSort(Reports);
	if (Visualise) {
		auto html = B->HTML( "external_scoring.html",  "External Test" );
		for (auto R:Reports) {
			html->WriteOne(R.get());
		}
		html->Finish();
		bh_logfiles(B);
	}

	return 0;
}



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
 
	if (Dest == stdout) {
		FileOut = "output";
	} else {
		printf( "Steve is sending %s randomness to: %s\n", ChanName.c_str(), FileOut.c_str() );
	}

	RandTest RT = {};	
	Histogram H = {};
	
	while (Remain > 0) {
		u32 This = min(DSize, Remain);
		bh_stats* Result = bh_hitbooks(B, &D[0], This);
		if (Result->Err)
			return Result->Err;

		RandStatsAccum(RT, H, &D[0], This);
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
	
	GenApproach App = {};
	RT.end(App);
	App.Stats.Hist = HistoInputRandomness(H);
	if (Dest != stdout)
		ReportStats(App, FileOut, std::cout);
	
	if (Hex) fputc('\n', Dest);
	fclose(Dest);

	return 0;
}


int main (int argc, const char* argv[]) {
	auto Args = ArgArray(argc, argv);
	int Err = ArgError;

	if (Args.size()) {
		//printf("Starting Temporal...\n");
		OrigPath = GetCWD();
		auto B = bh_create();
		errno = 0;

		if ( matchi(Args[0], "dump") ) {
			//printf("Dumping...\n");
			Err = DumpAction(B, Args, false);
		  
		} else if ( matchi(Args[0], "hexdump") ) {
			//printf("HexDumping...\n");
			Err = DumpAction(B, Args, true);
			
		} else if ( matchi(Args[0], "list") ) {
			//printf("Listing...\n");
			Err = ListAction(B, Args);
		  
		} else if ( matchi(Args[0], "read") ) {
			//printf("Reading...\n");
			Err = ViewAction(B, Args, false);
			
		} else if ( matchi(Args[0], "view") ) {
			//printf("Viewing...\n");
			Err = ViewAction(B, Args, true);
			
		} else {
			fprintf(stderr, "Unrecognised! %s\n", Args[0].c_str());
		}

		//printf("Cleaning Up...\n");
		bh_free(B);
		chduuhh(OrigPath.c_str());
	}

	if (Err == ArgError)
		printf(
"Usage: temporal dump     (0 to 127) (1KB to 1000MB) (file.bin)\n"
"       temporal hexdump  (0 to 127) (1KB to 1000MB) (file.txt)\n"
"       temporal list     (0 to 127)\n"
"       temporal read     (file.txt)\n"
"       temporal view     (/path/to/folder/)\n"
"\n"
"  About: http://randonauts.com/s/temporal \n");

	printf("\n");
	return Err;
}

