
extern "C" { // A simple C API!

BookHitter* tr_create(bool Log) {
	BookHitter* F = new BookHitter;
	require (F);

	*F = {};
	F->Log = Log;
	try {
		F->Allocate(512);
		F->CreateReps(0);
		CreateDirs();
	} catch (std::bad_alloc& e) {
		std::cerr << e.what();
	}
	return (BookHitter*)F;
}


void tr_free (BookHitter* f) {
	delete(f);
}


void tr_conf (BookHitter* f, int Channel, int* RepList) {
	f->UserChannel = Channel;
	f->CreateReps(RepList);
}



int tr_hitbooks (BookHitter* f, void* Data, int N, tr_output* Out) {
	*Out = {};
	auto &F = *f;
	if (Data) memset(Data, 0, N);
	
	RandomBuildup B = {.Remaining=N, .Data = (u8*)Data};
	while (F.RandomnessALittle(B, *Out))
		if (F.RandomnessBuild(B, *Out))
			return 0;

	F.ResetApproach();
	if (!f->Time.Error) f->Time.Error = -1;
	return f->Time.Error;
}


int main (int argc, const char* argv[]) {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
	
	const char* RestoreDir = getcwd(0, 0);
	puts(R"(Reesurrch iN2 teMpOwAls!!

Gennewaits pngs 4 u 2 chekk iFf dA randOmNesS "seems gud".

Uses da ~RAndoMnEss~ in "hoW loNg" da instruction taykes, 4 fizzicalie bassed raNdoMness.

No idea if dis RanDmoNess iz "gud"? Seems ~eggsiiting~! >:3
)");
	
	BookHitter& F = *tr_create(true);
	tr_output TROut;
	int Err = tr_hitbooks(&F, 0, 1, &TROut);
	const int Len = 4096;
	u8 DataBuff[Len] = {};
	
	ApproachVec V;
	for_(5) {
		Err = tr_hitbooks(&F, DataBuff, Len, &TROut);
		if (Err) break;
		WriteImg(DataBuff, Len, F.CollectInto(V, i+1));
	}
	
	if (F.App)
		F.CreateHTMLRandom(V, F.App->NameSub() + ".html");
	BookHitter::ClearArray(V);
	chdir(RestoreDir);
	return Err;
}

}
