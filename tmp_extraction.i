

static void DebiasSectionsOfLength (Histogram& H, u8* Start, int n, int x, GenApproach& App) {
	auto TF = H.FlipBits(x); // We won't add missing parts. it's just to break up computery patterns.
	if (TF.NoNeed())
		return;
		
	u64 Rand = App.StablePRndSeed(x);		
	
	bool Active = !App.IsSudo();
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
				if (Active) for_(Length)
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


static bool pdb (u8* Start, int i, int n, int Offness) {
	bool TestFor = (Offness > 0);
	u8* End = Start + std::min(i+2, n);

	for (u8* Curr = Start+i; Curr < End; Curr++) {
		if (((bool)*Curr) == TestFor) {
			*Curr = ((u32)TestFor) - 1;
			return true;
		}
	}

	return false;
}


static void PerfectBitDebias (u8* Start, int n, GenApproach& App) {
	auto TotalBits = BitCount(Start, n)>>3;
	int Offness = TotalBits - (n/2);
	int RandBitsNeeded = Log2i(n - 1);
	bool Active = !App.IsSudo();

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
			if (!Active or pdb(Start, (int)i, n, Offness))
				Offness += 1 - 2*(Offness > 0);
		}
	}
}


[[maybe_unused]] static void DebugPrintBuff(BookHitter& B) {
	for_(64*1024) {
		printf("%i, ", B.Buff[i]);
	}
	printf("\n");
}


static void Do_HistogramDebias (BookHitter& B, u8* Start, int n, bool Log) {
	if (n==9) DebugPrintBuff(B); // stop strip
	if (Log) {
		Histogram H2 = CollectHistogram(Start, n);
		DrawHistogram(B, H2, "");
	}
	
	Histogram H = CollectHistogram(Start, n);
	
	for (int i = BarCount - 1; i >= 1; i--)
		DebiasSectionsOfLength(H, Start, n, i, *B.App);
	PerfectBitDebias(Start, n, *B.App);
	
	if (Log) {
		Histogram H2 = CollectHistogram(Start, n);
		DrawHistogram(B, H2, "p");
	}
}


static int DoBytesToBits (u8* Bytes, int n, u8* Bits) {
	for_(n) {
		u32 c = Bytes[i];
		FOR_(oof, 8) {
			*Bits++ = ((c>>oof)&1)*255;
		}
	}
	
	return n*8;
}

static int DoBitsToBytes (u8* Bits, int n) {
	auto Cpy = CopyBytes(Bits, n);
	auto nSmall = n / 8;
	
	for_(nSmall) {
		int j = i<<3;
		int oof = (Bits[j] & 0x01) | (Bits[j+1] & 0x02) | (Bits[j+2] & 0x04) | (Bits[j+3] & 0x08) | (Bits[j+4] & 0x10) | (Bits[j+5] & 0x20) | (Bits[j+6] & 0x40) | (Bits[j+7] & 0x80);
		Bits[i] = oof;
	}

	// need to test it works...
	ByteArray Bits2(n);
	DoBytesToBits(&Bits[0], nSmall, &Bits2[0]);
	for_(n)
		if (Bits2[i] != Cpy[i])
			debugger;

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
	u32 Mul = 256 / Mod;

	FOR_ (i, n) {
		u32 V = Data[i]; 
		if (V > Cap) {
			V2 = uint64_hash(V2);
			V = (u32)V2;
		}
		V = (V % Mod) * Mul; // I think it helps? Not sure.
		*Write++ = (V & 1)-1;
	}
	
	return (int)(Write - Start);
}


static void ExtractRandomness (BookHitter& B, int Mod, bool Debias, bool Log) {
	B.App->Stats = {};

	int n = std::min(B.Space(), B.Time.Measurements);
	u8* Start = B.Extracted();
	
	n = DoModToBit			(B, Start, Mod, n);
	n = DoXorShrink			(Start, 16, n);
	if (Debias)
		Do_HistogramDebias	(B, Start, n, Log);
	n = DoBitsToBytes		(Start, n);

	B.App->Stats.Length = n;
}

