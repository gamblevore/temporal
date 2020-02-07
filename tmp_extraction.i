

static void DebiasSectionsOfLength (Histogram& H, u8* Start, int n, int x, GenApproach& App) {
	auto TF = H.FlipBits(x); // We won't add missing parts. it's just to break up computery patterns.
	if (TF.NoNeed())
		return;
		
	u64 Rand = App.StablePRndSeed(x);		
	
	bool Prev = Start[0];
	auto End = Start + n;
	auto Section = Start;
	u32  BitsRandomised = 0;
	
	for (u8* Curr = Start; Curr < End; Curr++ ) {
		if (*Curr != Prev) {
			int Length = (int)(Curr - Section);
			if (Length == x and TF.FlipThisBit(Prev)) {
			// don't alter histogram? assume it's mostly OK? just see how well it does.
				Rand = uint64_hash(Rand);
				BitsRandomised += Length;
				for_(Length)
					Curr[i] = ((Rand>>i) & 1) - 1;
			}
			Prev = !Prev;
			Section = Curr;
		}
	}
	
	App.Stats.BitsRandomised += BitsRandomised;
}


static int BitCount(u8* Start, int n) {
	int Result = 0;
	u64* Oof = (u64*)Start;
	u64* End = (u64*)(Start + n);
	while (Oof < End)
		Result += __builtin_popcountll(*Oof++);
	return Result;
}


static int pdb (u8* Start, int i, int n, int Offness) {
	bool TestFor = (Offness > 0);
	u8* End = Start + std::min(i+2, n);

	for (u8* Curr = Start+i; Curr < End; Curr++) {
		if (((bool)*Curr) == TestFor) {
			*Curr = ((u32)TestFor) - 1;
			return Offness + 1 - 2*(Offness > 0);
		}
	}

	return Offness;
}


static void PerfectBitDebias (u8* Start, int n, GenApproach& App) {
	auto TotalBits = BitCount(Start, n)>>3;
	int Offness = TotalBits - (n/2);
	int RandBitsNeeded = Log2i(n - 1);
	App.Stats.BitsRandomised += abs(Offness);
	
	u64 V2 = App.StablePRndSeed(Offness);
	if (!V2) debugger;
	
	for (int C = 0; Offness and C < 64*1024; C++ ) {
		u64 Rand = V2 = uint64_hash(V2);
		if (!V2) debugger;
		for (int r = 64; Offness and r > RandBitsNeeded; r -= RandBitsNeeded) {
			u64 i = (1<<RandBitsNeeded) - 1;
			i &= Rand;
			Rand >>= RandBitsNeeded;
			Offness = pdb(Start, (int)i, n, Offness);
		}
	}
}


static void Do_WindowScanDebias (BookHitter& B, u8* Start, int n) {
	// need some kinda array...
	// and a bit collector...
}


static void Do_HistogramDebias (BookHitter& B, u8* Start, int n) {
	if (B.LogOrDebug()) {
		Histogram H = CollectHistogram(Start, n);
		DrawHistogram(B, H, "");
	}


	Do_WindowScanDebias(B, Start, n);
	Histogram H = CollectHistogram(Start, n);
	
	for (int i = BarCount - 1; i >= 1; i--)
		DebiasSectionsOfLength(H, Start, n, i, *B.App);
	PerfectBitDebias(Start, n, *B.App);


	if (B.LogOrDebug()) {
		H = CollectHistogram(Start, n);
		DrawHistogram(B, H, "_d");
	}
}


static int DoBitsToBytes (u8* Bytes, int n) {
	auto nSmall = n / 8;
	
	for_(nSmall) {
		int j = i<<3;
		int oof = (Bytes[j] & 0x80) | (Bytes[j+1] & 0x40) | (Bytes[j+2] & 0x20) | (Bytes[j+3] & 0x10) | (Bytes[j+4] & 0x08) | (Bytes[j+5] & 0x04) | (Bytes[j+6] & 0x02) | (Bytes[j+7] & 0x01);
		Bytes[i] = oof;
	}
	
	return nSmall;
}


static int DoXorShrink (u8* Bytes, int Shrink, int n) {
	auto nSmall = n / Shrink;
	
	FOR_ (i, nSmall) {
		int Oof = 0;
		for (int x = 0; x < Shrink; x++)
			Oof = Oof xor Bytes[i*Shrink + x];
		Bytes[i] = Oof;
	}
	
	return nSmall;
}


static int DoModToBit (BookHitter& P, u8* Start, int Mod, int n) {
	auto Data = P.Out();
	u8* Write = Start;
	auto& App = *P.App;
	
	u32 H = App.Highest;
	u32 Cap = H - (H % Mod);
	if (App.IsSudo()) Cap = -1;
	u64 V2 = App.StablePRndSeed();

	FOR_ (i, n) {
		u32 V = Data[i]; 
		if (V > Cap) {
			V2 = uint64_hash(V2);
			V = (u32)V2;
		}
		V = (V % Mod) * (256/Mod); // no idea why im multiplying.
		*Write++ = (V % 2)-1;
	}
	
	return (int)(Write - Start);
}


static void ExtractRandomness (BookHitter& B, int Mod, bool Debias) {
	B.App->Stats = {};

	int n = std::min(B.Space(), B.Time.Measurements);
	u8* Start = B.Extracted();
	
	n = DoModToBit			(B, Start, Mod, n);
	n = DoXorShrink			(Start, 16, n);
	if (Debias)
		Do_HistogramDebias	(B, Start, n);
	n = DoBitsToBytes		(Start, n);

	B.App->Stats.Length = n;
}

