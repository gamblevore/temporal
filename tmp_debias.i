

Ooof void VerifyBSL (BitSections Sections, BitView R) {
	ByteArray RoundTrip(R.ByteLength()+100, 0);
	auto R2 = Sections.Convert(&RoundTrip[0]);
	
	if (R2.Length != R.Length) debugger;
	FOR_(j, R.ByteLength()) {
		auto r = R2.Data[j];
		auto o = R.Data[j];
		if (r!=o) debugger;
	}
}


Ooof void DebugSamples (BookHitter& B) {
	auto Name = B.App->Name();
	printf("Samples for %s:\n", Name.c_str());
	auto S = B.Out();
	for_ (std::min(1000, B.Space()))
		printf("%i, ", S[i]);
	printf("0\n");
}


Ooof void DebugPrintBuff(u8* Addr, int n) {
	for_(n)
		printf("%i, ", Addr[i]);
	printf("\n");
}


Ooof bool CanUseLength(int FoundLength, int SearchLength) {
	if (FoundLength == SearchLength) return true;
	if (FoundLength >= 15 and SearchLength == BarCount-1) return true;
	// actually... we should lower BarCount down to... 16 
	return false;
}


// Need a one-pass sliding window system...
Ooof BitSections DebiasSectionsOfLength (Histogram& H, BitSections R, GenApproach* App) {
	int x = 0;
	auto TF = H.FlipBits(x);
	if (TF.NoNeed())
		return R;
			
	for_ (10) {
		bool Prev = false;

		if (TF.FlipThisBit(Prev)) {
			// flip
		}
	}
	
	
	return R;
}


static bool pdb (BitView& R, u32 i, int Offness) {
	bool T = (Offness > 0);
	u32 n = std::min(i + 2, R.Length);

	for (; i < n; i++) {
		if (R[i] == T) {
			R.Set(i, !T);
			return true;
		}
	}

	return false;
}


static void PerfectBitDebias (BitView R, GenApproach* App, u32 TotalBits) {
	int n = R.Length;
	int Offness = TotalBits - (n/2);
	App->Stats.BitsRandomised += abs(Offness);
	if (App->IsSudo())
		return;

	std::default_random_engine generator;
	std::uniform_int_distribution<int> distribution(0, n);
	
	for (int C = 0; Offness and C < n/2; C++ )
		if (pdb(R, distribution(generator), Offness))
			Offness -= Sign(Offness);
}


static BitView Do_Histo (BookHitter& B, BitView R, Shrinkers Flags) {
	int n = R.Length;
	if (n < 64)  return R;
		
	auto Sections = R.Convert(B.BitSections());
	#if DEBUG
		VerifyBSL(Sections, R);
	#endif
	
	Histogram H = CollectHistogram(Sections);
	B.App->Stats.Hist = HistoInputRandomness(H);
	
	if (Flags.Histo) {
		if (AllowDebiaser)
			Sections = DebiasSectionsOfLength(H, Sections, B.App);

		R = Sections.Convert(R.Data);
		PerfectBitDebias(R, B.App, H[0][1]);
	}
	
	if (Flags.Log) { // no point logging this, if we didn't use DebiasSectionsOfLength
		Histogram H2 = CollectHistogram(Sections);
		DrawHistogram(B, H2, n, "");
	}
	
	return R;
}



