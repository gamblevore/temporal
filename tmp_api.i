


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


void bh_logfiles(BookHitter* f) {
	for (auto S : FilesToOpenLater)
		OpenFile(S);
}


void bh_free (BookHitter* f) {
	delete(f);
}


void bh_set_reps (BookHitter* f, int* RepList) {
	f->CreateReps(RepList);
}


bh_conf* bh_config (BookHitter* f) {
	return &f->Conf;
}


bh_stats* BookHitter::Hit (u8* Data, int DataLength) {
	if (!Data) return 0; // wat?

	CreateDirs();

	memset(Data, 0, DataLength);
	RandomBuildup B = {Data, DataLength, IsRetro()};
	Stats = {};

	while (CollectPieceOfRandom(B)) {
		B.Loops = 0;
	}

	if (Conf.AutoRetest)
		Retest();
		
	return &Stats;
}


bh_stats* bh_hitbooks (BookHitter* B, u8* Data, int DataLength) {
	return B->Hit(Data, DataLength);
}


static void ReportStuff (bh_stats* Result) {
	float M = ((float)(Result->SamplesGenerated))/1000000.0;
	float K = ((float)(Result->SamplesGenerated))/1000.0;
	
	if (M > 0.1)
		printf(":: %.2fM", M);
	  else
		printf(":: %.2fK", K);
	printf(" samples⇝%iKB ::\n", (Result->BytesOut/1024));
}


uSample* bh_extract_input(BookHitter* B, int N) {
	try {
		B->Allocate(N);
		return B->Out();
	} catch (std::bad_alloc& e) {
		std::cerr << e.what();
	}
	return 0;
}


int bh_extract_perform(BookHitter* B_, uSample* Samples, int N, bh_stats* Out) {
	auto B = *B_;
	GenApproach App = {};
	B.App = &App;
	
	FindSpikesAndLowest(B.Out(),  N,  B);	
	PreProcess(B);
	
	return B.UseApproach();
}

