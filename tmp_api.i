


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
	f->Log_ = Active;
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

	f->CreateDirs();

	memset(Data, 0, DataLength);
	RandomBuildup B = {Data, DataLength, f->IsRetro()};
	f->Time = {};

	while (f->CollectPieceOfRandom(B)) {
		; // boop;
	}
	
	return &f->Time;
}


void bh_report_speed (bh_output* Result) {
	float M = ((float)(Result->SamplesGenerated))/1000000.0;
	float K = ((float)(Result->SamplesGenerated))/1000.0;
	
	if (M > 0.1)
		printf("%.2fM", M);
	  else
		printf("%.2fK", K);
	printf(" samples⇝%iKB @ %.2fs", (Result->BytesOut/1024), Result->GenerateTime + Result->ProcessTime);
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

