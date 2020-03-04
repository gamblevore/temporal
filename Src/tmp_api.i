
#pragma GCC visibility push(default)


BookHitter* bh_create() {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
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
	FilesToOpenLater.clear();
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


bh_stats* bh_hitbooks (BookHitter* B, u8* Data, int DataLength) {
	return B->Hit(Data, DataLength);
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

#pragma GCC visibility pop


