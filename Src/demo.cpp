

#include "temporal_root.i"


static const char* WelcomeMsg = R"(Reesurrch iN2 teMpOwAls!!

Uses WAndoMness in "hoW loNg" da instruction taykes, 4 fizicks raNdoMness.

)";


static int RunTemporalDemo(int Chan) {
	const int NumBytes = 16*1024; 
	ByteArray D(NumBytes, 0);

	puts(WelcomeMsg);
	
	auto F = bh_create();
	auto& Conf = *bh_config(F); 
	Conf.Log = true;
	Conf.Channel = Chan;
	Conf.DontSortRetro = true;
//	Conf.AutoRetest = 1;

	auto Result = bh_hitbooks(F, &D[0], 1);
	auto html = F->HTML("temporal.html",  "Randomness Test");
	
	for_(16) {
		if (Result->Err) break;
		F->DebugLoopCount = i + 1;
		Result = bh_hitbooks(F, &D[0], NumBytes);
		
		if (i==0)
			ReportStuff(Result);

		auto App = F->App;
		auto s = App->Name();
		printf( ":: %i:  %s (", i + 1, s.c_str() );
		printf( "%.3fs) ::\n", Result->GenerateTime + Result->ProcessTime );
		html->WriteOne(App);
	}
	
	html->Finish();
	bh_logfiles(F);
	bh_free(F);

	return Result->Err;
}


// temporal 1    file.rnd 1024000
// temporal chan fileout  KBsize

int main (int argc, const char* argv[]) {
	auto RestoreDir = getcwd(0, 0);
	int Chan = argv[1] ? atoi(argv[1]) : 0;
	string FileOut  = (argc >= 3) ? argv[2]       : "";
	int SizeFileOut = (argc >= 4) ? atoi(argv[3]) : 0;
	
	
	
	int Err = RunTemporalDemo(Chan);
	printf("\n");
	IgnoredError = chdir(RestoreDir);
	return Err;
}

