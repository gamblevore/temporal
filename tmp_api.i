


BookHitter* bh_create() {
	auto G = new BookHitter;
	auto& F = *G;
	require (G);

	*G = {};

	try {
		StopStrip(F); // for debugging
		F.Allocate(1<<22);
		F.CreateReps(0);
	} catch (std::bad_alloc& e) {
		std::cerr << e.what();
	}
	return G;
}


void bh_use_log(BookHitter* f, bool Active) {
	f->Log = Active;
	if (Active)
		f->CreateDirs();
}


void bh_logfiles(BookHitter* f) {
	for (auto S : FilesToOpenLater)
		OpenFile(S);
}


void bh_free (BookHitter* f) {
	delete(f);
}


void bh_use_channel (BookHitter* f, int Channel) {
	f->UserChannel = Channel;
	f->ResetApproach();
}


void bh_set_reps (BookHitter* f, int* RepList) {
	f->CreateReps(RepList);
}


bh_output* bh_hitbooks (BookHitter* f, u8* Data, int DataLength) {
	if (!Data) return 0; // wat?

	memset(Data, 0, DataLength);
	RandomBuildup B = {Data, DataLength, f->IsRetro()};
	f->Time = {};
	f->OnlyNeedSize(DataLength);
	while (f->CollectPieceOfRandom(B));
	return &f->Time;
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
	
	FindSpikesAndLowest(B.Out(),  N,  B);	
	PreProcess(B);
	
	return B.UseApproach();
}

