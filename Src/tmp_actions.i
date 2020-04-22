



static cstring WelcomeMsg = R"(teMpOwAl resurtch!!

Steve is about to divulge magical temporal randomness from the brain of your device.
)";


static int ListAction (BookHitter* B, StringVec& Args) {
	if (Args.size() < 2) return ArgError;
	const int NumBytes = 16 * 1024; 
	ByteArray D(NumBytes, 0);
	
	auto& Conf = *bh_config(B);

	Conf.Log = true;
	B->SetChannel( GetArg(Args, 1).c_str() );
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


static void ReportStats(GenApproach& R,  string Name,  std::ostream& ofs) {
	if (Name.length())
		printf( "Non-randomness in: %s (lower is better)\n", Name.c_str() );

	int F = R.Stats.FailedIndexes;
	for_ (5) {
		ofs << "\t";
		ofs << ScoreNames[i].substr(0,5) + ": ";
		ofs << std::fixed << std::setprecision(3) << R[i];
		ofs << (((1<<i) & F) ? " ❌" : "");
		ofs << "\n";
	}
	ofs << "\n";
}


static int ReadMemoryAction (GenApproach& R, u8* Addr, u32 Len, std::ostream& ofs, string Name) {
	if (AllHex(Addr, Len))
		Len = HexCleanup(Addr, Addr, Len);
	FullRandomnessDetect(R, Addr, Len);
	ReportStats(R, Name, ofs);
	return 0;
}


static int ReadStrAction (GenApproach& R, string S, std::ostream& ofs, string Name) {
	u8* Addr = (u8*)S.c_str();
	u32 Len  = (u32)S.length();
	return ReadMemoryAction( R, Addr, Len, ofs, Name );
}


int ExpectedDir(cstring P) {
	debugger;
	if (cmatchi(P, "")) {
		if (!errno) {
			errno = ENOENT;
			fprintf(stderr, "Expected a directory, none specified.");
		}
	} else {
		fprintf(stderr, "Expected a directory at: %s\n", P);
	}
	return errno;
}


bool ViewAcceptFile(string Item, string FullPath) {
	if (Item[0] == '.') return false;
	if (fisdir(FullPath.c_str())) return false;
	return true;
}


static int ViewAction (BookHitter* B, StringVec& Args, bool Visualise) {
	auto Path = ArrRead(Args,1);
	if (Path == "_") Path = "";
	if (Path != "") {
		Path = ResolvePath(Path);
		if (!fisdir(Path.c_str())) {
			return ExpectedDir(Args[1].c_str());
		}
	}

	string OutFol = "";
	if (Args.size() >= 3) {
		auto S = Args[2].c_str();
		if (!fexists(S)) {
			mkduuhh(S);
		}
		OutFol = ResolvePath(S);
		if (OutFol == "") {
			return ExpectedDir(S);
		}
	}
	
	B->ExternalReports(OutFol);
	ApproachVec Reports;
	
	if (Path == "") {
		auto R = B->ExternalGen("stdin", Visualise);
		Reports.push_back(R);
		string StdIn = (Args.size() >= 3) ? Args[2] : ReadStdin();
		ReadStrAction( *R, StdIn, std::cout, "stdin" );
	} else {
		DirReader D = Path;
		while (D.Next()) {
			auto Item = D.Name();
			auto FullPath = Path + "/" + Item;
			if (ViewAcceptFile(Item, FullPath)) {
				auto FileData = ReadFile(FullPath, 0x7fffFFFF);
				if (!FileData.length()) continue;
				
				auto R = B->ExternalGen(Item, Visualise);
				Reports.push_back(R);
				ReadStrAction( *R, FileData, std::cout, Item );
			}
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
	if (Args.size() < 3)
		return ArgError;
	
	bh_config(B)->Log = -1; // no log even debug
	B->SetChannel(GetArg(Args,1).c_str());
	
	int          Remain   = ParseLength(Args[2]);
	if (Hex)	 Remain  /= 2;
	if (!Remain) return errno;
	string       FileOut  = ArrRead(Args,3);
	FILE*        Dest     = CmdArgFile(FileOut, stdout);
	if (!Dest)   return errno;

	auto TStart = Now();
	u32 Written = 0;
	int OldSeconds = 0;
	int DSize = 64 * 1024;
	int HSize = DSize;
	if (Hex) HSize *= 2;
	ByteArray D(HSize, 0);

	auto Chan = B->ViewChannel("DumpAction");
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
		Remain  -= This;
		Written += This;
		if (Result->Err)
			return Result->Err;

		
		RandStatsAccum(RT, H, &D[0], This);
		if (Hex)
			This = InPlaceConvertToHex(&D[0], This);
		fwrite(&D[0], 1, This, Dest);

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


static int PrintAction (BookHitter* B, StringVec& Args) {
	// assume chaotic?
	bh_config(B)->Log = -1; // no log even debug
	bh_config(B)->Channel = 0;
	string S = B->ViewChannel("PrintAction")->Name();
	printf( "printing temporal %s\n", S.c_str() );

	int N = ParseLength(Args[1]);

	for_(N) {
		if (i)
			printf(", ");
		u64 X = bh_rand_u64(B);
		printf("%lli", X);
	}
	printf("\n");
	return 0;
}


static int UnarchiveAction (BookHitter* B, StringVec& Args) {
	// input-fiel, output-file.
	if (Args.size() < 3) return ArgError;
		
	auto Data = ReadFile(Args[1]);
	if (!errno)
		Archive::WriteAnyway(Data, Args[2]);
	return errno;
}
