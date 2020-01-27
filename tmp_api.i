
extern "C" { // A simple C API!

static const char* WelcomeMsg = R"(Reesurrch iN2 teMpOwAls!!

Gennewaits pngs 4 u 2 chekk iFf dA randOmNesS "seems gud".

Uses da ~RAndoMnEss~ in "hoW loNg" da instruction taykes, 4 fizzicalie bassed raNdoMness.

No idea if dis RanDmoNess iz "gud"? Seems ~eggsiiting~! >:3
)";


BookHitter* tr_create(bool Log) {
	auto G = new BookHitter;
	auto& F = *G;
	require (G);

	F = {};
	F.Log = Log;

	try {
		F.Allocate(512);
		F.CreateReps(0);
		if (!F.Log)
			F.LoadLists();
	} catch (std::bad_alloc& e) {
		std::cerr << e.what();
	}
	return G;
}


void tr_free (BookHitter* f) {
	delete(f);
}


void tr_conf (BookHitter* f, int Channel, int* RepList) {
	f->UserChannel = Channel;
	f->CreateReps(RepList);
}


int tr_hitbooks (BookHitter* f, bh_output* Out) {
	Out->GenerateTime = 0; Out->WorstScore = 0; Out->ProcessTime = 0;
	auto &F = *f;
	if (Out->Data) memset(Out->Data, 0, Out->N);
	
	RandomBuildup B = {}; B.Remaining=Out->N; B.Data = (u8*)Out->Data;
	while (F.RandomnessALittle(B, *Out))
		if (F.RandomnessBuild(B, *Out))
			return 0;

	F.ResetApproach();
	if (!f->Time.Error) f->Time.Error = -1;
	return f->Time.Error;
}


static const char* RestoreDir;
static void CleanupMain () {
	IgnoredError = chdir(RestoreDir);
}


int main (int argc, const char* argv[]) {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
	
	RestoreDir = getcwd(0, 0);
	atexit(CleanupMain);
	puts(WelcomeMsg);
	
	bh_output TROut = {0, 1};
	BookHitter& F = *tr_create(true);
	int Err = tr_hitbooks(&F, &TROut);

	u8 DataBuff[4096];
	TROut = {DataBuff, sizeof(DataBuff)};
	ApproachVec V;
	
	for_(5) {
		Err = tr_hitbooks(&F, &TROut);
		if (Err) break;
		WriteImg(DataBuff, TROut.N, F.CollectInto(V, i+1));
	}
	
	if (F.App)
		F.CreateHTMLRandom(V,  F.App->NameSub() + ".html",  "Randomness Test");
	return Err;
}

}
