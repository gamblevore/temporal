

static void DebiasSome (Histogram& H, u8* Curr, int n, bool Value) {
// so... do we keep the histogram intact?
// because we'll have altered the white/black next to it.
// we can assume it's mostly OK I think? just see how well it does before correcting anything?
	u64 Rand = Random64();
	for_(n) {
		u32 b = Rand & 1;
		*Curr++ = b - 1;
		Rand <<= 1;
	}
}


static void DebiasAll (Histogram& H, u8* Start, int n, int x) {
	auto TF = H.FlipBits(x); // We won't add missing parts. it's just to break up computery patterns.
	if (TF.NoNeed())
		return;
	
	bool Prev = Start[0];
	auto End = Start + n;
	auto Section = Start;
	for (u8* Curr = Start; Curr < End; Curr++ ) {
		if (*Curr != Prev) {
			int Length = (int)(Curr - Section);
			if (Length == x and TF.FlipThisBit(Prev))
				DebiasSome(H, Section, Length, Prev);
			Prev = !Prev;
			Section = Curr;
		}
	}
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


static void PerfectBitDebias (u8* Start, int n) {
	auto TotalBits = BitCount(Start, n)>>3;
	int Offness = TotalBits - (n/2);
	int RandBitsNeeded = Log2i(n-1);

	while (Offness) {
		u64 Rand = Random64();
		for (int r = 64; Offness and r > RandBitsNeeded; r -= RandBitsNeeded) {
			u64 i = (1<<RandBitsNeeded) - 1;
			i &= Rand;
			Rand >>= RandBitsNeeded;
			Offness = pdb(Start, (int)i, n, Offness);
		}
	}
	
	TotalBits = BitCount(Start, n)>>3;
	if (TotalBits!=n/2) debugger;
}


static void Do_Debias (BookHitter& B, u8* Start, int n) {
	Histogram H = CollectHistogram(Start, n);
	if (B.LogOrDebug())
		DrawHistogram(B, H);
	
	for (int i = BarCount - 1; i >= 1; i--)
		DebiasAll(H, Start, n, i);

	PerfectBitDebias(Start, n);

	if (B.LogOrDebug()) {
		H = CollectHistogram(Start, n);
		DrawHistogram(B, H, "After");
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
	u32 Cap = 256 - (256 % Mod);
	if (P.App->IsSudo()) Cap = -1;
	FOR_ (i, n) {
		u32 V = Data[i]; 
		if (V > Cap)
			V = (u32)Random64();
		V = (V % Mod) * (256/Mod); // no idea why im multiplying.
		*Write++ = (V % 2)-1;
	}
	
	return (int)(Write - Start);
}


static void ExtractRandomness (BookHitter& B, int Mod) {
	int n = B.Space();
	n = std::min(n, B.Time.Measurements);
	u8* Start = B.Extracted();
	n = DoModToBit			(B, Start, Mod, n);
	n = DoXorShrink			(Start, 16, n);
	    Do_Debias			(B, Start, n);
	n = DoBitsToBytes		(Start, n);
	B.App->Stats = {};
	B.App->Stats.Length = n;
}

