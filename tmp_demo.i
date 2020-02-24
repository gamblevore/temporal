

static const char* WelcomeMsg = R"(Reesurrch iN2 teMpOwAls!!

Uses da ~RAndoMnEss~ in "hoW loNg" da instruction taykes, 4 fizzicalie bassed raNdoMness.

Seems ~eggsiiting~! >:3

Steve will bee pleezed :>
)";


static int RunTemporalDemo(int Chan) {
	const int NumBytes = 16*1024; 
	ByteArray D(NumBytes, 0);

	puts(WelcomeMsg);
	
	auto F = bh_create();
	bh_config(F)->Log = true;
	bh_config(F)->Channel = Chan;
//	bh_config(F)->AutoRetest = 1;

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


int main (int argc, const char* argv[]) {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
	auto RestoreDir = getcwd(0, 0);
	int Chan = argv[1]?atoi(argv[1]):0; 
	int Err = RunTemporalDemo(Chan);
	printf("\n");
	IgnoredError = chdir(RestoreDir);
	return Err;
}

