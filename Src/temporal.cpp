

#include "temporal_root.i"



static const char* WelcomeMsg = R"(Reesurrch iN2 teMpOwAls!!

Uses WAndoMness in "hoW loNg" da instruction taykes.

)";


static int ScoreAction (int argc, const char* argv[]) {
	if (argc!=3)
		return ArgError;
	int Chan = argv[2] ? atoi(argv[2]) : 0;

	const int NumBytes = 16*1024; 
	ByteArray D(NumBytes, 0);

	puts(WelcomeMsg);
	
	auto F = bh_create();
	auto& Conf = *bh_config(F); 
	Conf.Log = true;
	F->SetChannel( Chan );
//	Conf.DontSortRetro = true;
//	Conf.AutoRetest = 1;

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



// temporal 1    1024000 file.rnd 
// temporal chan size    fileout

int DumpAction (int argc, const char* argv[]) {
	if (argc < 4)
		return ArgError;
	
	auto F = bh_create();
	bh_config(F)->Log = -1; // no log even debug
	F->SetChannel(atoi(argv[2]));
	int          Remain   = ParseLength(argv[3]);
	string       FileOut  = argv[4] ? argv[4] : "";
	if (!Remain) return errno;
	FILE*        Dest     = CmdArgFile(FileOut);
	if (!Dest)   return errno;

	auto TStart = Now();
	u32 Written = 0;
	int OldSeconds = 0;
	int DSize = 256 * 1024;
	ByteArray D(DSize, 0);
	
	printf( "Steve is writing randomness to: %s\n", FileOut.c_str() );
	
	while (Remain > 0) {
		u32 This = min(DSize, Remain);
		bh_stats* Result = bh_hitbooks(F, &D[0], This);
		if (Result->Err) return Result->Err;
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
	auto Action = argv[1];
	int Err = ArgError;

	if ( matchi(Action, "dump") )
		Err = DumpAction(argc, argv);
	  else if ( matchi(Action, "score") )
		Err = ScoreAction(argc, argv);
	
	if (Err == ArgError)
		printf(
"Usage: temporal dump  (channel) (amount) (file)\n"
"  (or)\n"
"       temporal score (channel)\n");


	printf("\n");
	IgnoredError = chdir(RestoreDir);
	return Err;
}

