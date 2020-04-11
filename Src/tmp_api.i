
#pragma GCC visibility push(default)


BookHitter* bh_create() {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
	auto G = new BookHitter;
	require (G);

	auto& F = *G;
	F = {};
	F.Conf.WarmupMul = 2;	// retro only... makes graphics look better? (experimentally only... there is no reason behind it and finding good generators for graphical output is an art not a science.)
	F.Conf.Channel = 1;   	// faster and better for most people.
	F.Conf.AutoReScore = 1; // Keep intention-detection strong. Shouldn't affect randomness...

	try {
		HexCharsInit();
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
	delete(f); // already checks for nil
}


void bh_set_reps (BookHitter* f, int* RepList) {
	f->CreateReps(RepList);
}


bh_conf* bh_config (BookHitter* f) {
	return &f->Conf;
}


bh_stats* bh_hitbooks (BookHitter* B, u8* Data, int DataLength, bool Hex) {
	int N = DataLength;
	if (Hex)
		N /= 2;
	auto Result = B->Hit(Data, N);
	if (Hex)
		InPlaceConvertToHex(Data, N);
	return Result;
}


//
//struct bh_colorise_output {
//	u8* colors;
//	int	length;
//	u8* description;
//};
//
//
//void bh_colorise_external(u8* data, int length, bh_colorise_output* output);
//

int bh_colorise_external(u8* Data, int N, u8* WriteTo) {
	if (WriteTo and Data)
		ColoriseSamples(Data, WriteTo, N);
	return N*4; // size-needed.
}


int bh_view_colorised_samples (BookHitter* B, u8* Out, int OutLength) {
	int InputBytes = RetroCount * 8; // 64-bit values, means 8-bytes per value
	int BytesAvail = InputBytes * 4; // rgba... cos each byte is turned into 4 bytes.
	if (!Out)
		return BytesAvail;

	OutLength = min(OutLength, BytesAvail);
	ColoriseSamples(B->Extracted(), Out, InputBytes);

	return BytesAvail;
}


int bh_view_rawsamples (BookHitter* B, u8* Out, int OutLength) {
	int InputBytes = RetroCount * 8;
	int BytesAvail = InputBytes;
	if (!Out)
		return BytesAvail;

	OutLength = min(OutLength, BytesAvail);
	memcpy(Out, B->Extracted(), OutLength);
	
	return BytesAvail;
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
	auto& B = *B_;
	GenApproach App = {};
	B.App = &App;
	
	FindLowest(B.Out(),  N,  B);	
	PreProcess(B);
	
	return B.UseApproach(true);
}


#pragma GCC visibility pop


