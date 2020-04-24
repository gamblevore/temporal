
#pragma GCC visibility push(default)


BookHitter* bh_create() {
	sizecheck(u64, 8);  sizecheck(u32, 4);  sizecheck(u16, 2);  sizecheck(u8, 1);
	auto G = new BookHitter;
	require (G);

	auto& F = *G;
	F = {};
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


bool bh_isdebug() {
	return DEBUG_AS_NUM;
}


void bh_logfiles(BookHitter* B) {
	auto& A = *B->Arc;
	A.Close();
	auto List = A.Files;
	A.Files = {};

	if (!B->LogFiles() or !A.WriteToDisk)
		return;
	
	for (auto& F : List)
		if (Suffix(F->FullPath()) == "html" and F->OpenMe)
			OpenFile(F->FullPath());
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

int bh_setchannel_num (BookHitter* B, int i) {
	int N = (int)B->RetroApproaches.size();
	int i2 = min(abs(i), N);
	i = Sign(i)*i2;
	B->Conf.Channel = i;
	return B->Conf.Channel; 
}



bh_stats* bh_hitbooks2 (BookHitter* B, u8* Data, int DataLength, bool Hex) {
	int N = DataLength;
	if (Hex)
		N /= 2;
	auto Result = B->Hit(Data, N);
	if (Hex)
		InPlaceConvertToHex(Data, N);
	return Result;
}


bh_stats* bh_hitbooks (BookHitter* B, u8* Data, int DataLength) {
	return bh_hitbooks2(B, Data, DataLength, false); 
}

u64 bh_rand_u64 (BookHitter* B) {
	return *((u64*)bh_rand_ptr(B, sizeof(u64)));
}

double bh_rand_double (BookHitter* B) {
	const double iwtf2 = 1.0 / 18446744073709551616.0;
	return (double)bh_rand_u64(B) * iwtf2; 
}

u32 bh_rand_u32 (BookHitter* B) {
	return *((u32*)bh_rand_ptr(B, sizeof(u32)));
}

float bh_rand_float (BookHitter* B) {
	const float iwtf2 = 1.0 / 4294967296.0;
	return (float)bh_rand_u32(B) * iwtf2; 
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


