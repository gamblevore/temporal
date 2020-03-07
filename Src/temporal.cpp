

#include "temporal_root.i"



static const char* WelcomeMsg = R"(Reesurrch iN2 teMpOwAls!!

Uses WAndoMness in "hoW loNg" da instruction taykes.

)";


static int ScoreAction (StringVec& Args) {
	if (Args.size()!=3)
		return ArgError;
	int Chan = Num(Args[1]);

	const int NumBytes = 16*1024; 
	ByteArray D(NumBytes, 0);

	puts(WelcomeMsg);
	
	auto F = bh_create();
	auto& Conf = *bh_config(F); 
	Conf.Log = true;
	F->SetChannel( Chan );
	Conf.DontSortRetro = true;
//	Conf.AutoReScore = 1;

	auto Result = bh_hitbooks(F, &D[0], 1);
	auto html = F->HTML("temporal.html",  "Randomness Test");
	
	for_(16) {
		if (Result->Err) break;
		F->DebugLoopCount = i + 1;
		Result = bh_hitbooks(F, &D[0], NumBytes);
		
		if (i == 0)
			ReportStuff(Result);

		auto App = F->App;
		auto s = App->Name();
		printf( ":: %i:  %s (", i + 1,  s.c_str() );
		printf( "%.3fs) ::\n",  Result->GenerateTime + Result->ProcessTime );
		html->WriteOne(App);
	}
	
	html->Finish();
	bh_logfiles(F);
	bh_free(F);

	return Result->Err;
}



// temporal dump   1    1024000 file.rnd hex

int DumpAction (StringVec& Args, bool Hex) {
	if (Args.size() < 4)
		return ArgError;
	
	auto F = bh_create();
	bh_config(F)->Log = -1; // no log even debug
	F->SetChannel(Num(Args[1]));
	
	int          Remain   = ParseLength(Args[2]);
	string       FileOut  = Args[3];
	FILE*        Dest     = CmdArgFile(FileOut);
	if (!Remain) return errno;
	if (!Dest)   return errno;

	auto TStart = Now();
	u32 Written = 0;
	int OldSeconds = 0;
	int DSize = 64 * 1024;
	ByteArray D(DSize, 0);
	
	printf( "Steve is writing randomness to: %s\n", FileOut.c_str() );
	
	while (Remain > 0) {
		u32 This = min(DSize, Remain);
		bh_stats* Result = bh_hitbooks(F, &D[0], This);
		if (Result->Err) return Result->Err;
		if (Hex) for_(This)
			fhex(D[i], Dest);
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

	fclose(Dest);
	bh_free(F);
	return 0;
}


int main (int argc, const char* argv[]) {
	auto RestoreDir = getcwd(0, 0);
	auto Args = ArgArray(argc, argv);
	int Err = ArgError;

	if ( matchi(Args[0], "dump") )
		Err = DumpAction(Args, false);
	  else if ( matchi(Args[0], "hexdump") )
		Err = DumpAction(Args, true);
	  else if ( matchi(Args[0], "score") )
		Err = ScoreAction(Args);

	if (Err == ArgError)
		printf(
"Usage: temporal dump     (-50 to 50) (1KB to 100MB) (file.txt)\n"
"  (or)\n"
"       temporal hexdump  (-50 to 50) (1KB to 100MB) (file.txt)\n"
"  (or)\n"
"       temporal score    (-50 to 50)\n");

	printf("\n");
	IgnoredError = chdir(RestoreDir);
	return Err;
}

