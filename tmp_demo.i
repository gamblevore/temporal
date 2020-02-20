

static const char* WelcomeMsg = R"(Reesurrch iN2 teMpOwAls!!

Uses da ~RAndoMnEss~ in "hoW loNg" da instruction taykes, 4 fizzicalie bassed raNdoMness.

Seems ~eggsiiting~! >:3

Steve will bee pleezed :>
)";


static int RunTemporalDemo() {
	const int NumBytes = 4096; 
	ByteArray D(NumBytes, 0);

	puts(WelcomeMsg);
	
	auto F = bh_create();
	bh_use_log(F, true);

	auto Result = bh_hitbooks(F, &D[0], 1);
	auto html = F->HTML("temporal.html",  "Randomness Test");
	
	for_(5) {
		if (Result->Err) break;
		F->App->NumForName = i + 1; 
		Result = bh_hitbooks(F, &D[0], NumBytes);
		html->WriteOne(F->App);
	}
	
	html->Finish();
	bh_logfiles(F);
	bh_free(F);

	return Result->Err;
}


static string RestoreDir;
static void CleanupMain () {
	IgnoredError = chdir(RestoreDir.c_str());
}


int main (int argc, const char* argv[]) {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
	RestoreDir = getcwd(0, 0);
	atexit(CleanupMain);
	int Err = RunTemporalDemo();
	printf("\n");
	return Err;
}

