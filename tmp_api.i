


BookHitter* bh_create() {
	auto G = new BookHitter;
	auto& F = *G;
	require (G);

	*G = {};

	try {
		F.StopStrip(); // for debugging
		F.Allocate(1<<(21+DEBUG_AS_NUM));
		F.CreateReps(0);
		F.LoadLists();
	} catch (std::bad_alloc& e) {
		std::cerr << e.what();
	}
	return G;
}


void bh_use_log(BookHitter* f, bool Active) {
	f->Log = Active;
	if (Active) {
		f->CPU_Modes = {};
		f->CreateDirs();
	}
}


void bh_logfiles(BookHitter* f) {
	for (auto S : FilesToOpenLater)
		OpenFile(S);
}


void bh_free (BookHitter* f) {
	delete(f);
}


void bh_use_temporal (BookHitter* f, int Channel) {
	f->UserChannel = Channel;
	f->CreationMode = kModeTemporal;
}


void bh_use_retro (BookHitter* f, int Channel) {
	f->UserChannel = Channel;
	f->CreationMode = kModeRetroCausal;
}


void bh_use_pseudo (BookHitter* f) {
	f->UserChannel = 0;
	f->CreationMode = kModePseudo;
}


void bh_set_reps (BookHitter* f, int* RepList) {
	f->CreateReps(RepList);
}


bh_output bh_hitbooks (BookHitter* f, u8* Data, int DataLength) {
	auto &F = *f;
	if (Data) memset(Data, 0, DataLength);
	
	RandomBuildup B = {Data, DataLength};
	bh_output Result = {};
	while (F.CollectPieceOfRandom(B, Result))
		if (F.AssembleRandoms(B, Result))
			return Result;

	F.ResetApproach();
	Result.Err = f->Time.Error;
	if (!Result.Err) Result.Err = -1;
	return Result;
}


uSample* bh_pre_extract(BookHitter* B, int N) {
	try {
		B->Allocate(N);
		return B->Out();
	} catch (std::bad_alloc& e) {
		std::cerr << e.what();
	}
	return 0;
}


int bh_extract_entropy(BookHitter* B_, uSample* Samples, int N, bh_output* Out) {
	auto B = *B_;
	GenApproach App = {};
	B.App = &App;
	
	FindSpikesAndLowest(B.Out(),  N,  B,  false);	
	PreProcess(B);
	
	return B.UseApproach(Out);
}

