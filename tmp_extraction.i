

static void DebugPrintBuff(u8* Addr, int n) {
	for_(n)
		printf("%i, ", Addr[i]);
	printf("\n");
}


static bool CanUseLength(int FoundLength, int SearchLength) {
	if (FoundLength == SearchLength) return true;
	if (FoundLength >= 15 and SearchLength == BarCount-1) return true;
	// actually... we should lower BarCount down to... 16 
	return false;
}


static int DebiasSectionsOfLength (Histogram& H, u8* Start, int n, int x, GenApproach* App) {
	auto TF = H.FlipBits(x); // We won't add missing parts. it's just to break up computery patterns.
	if (TF.NoNeed())
		return n;
		
	bool Active = !App->IsSudo();
	bool Prev = Start[0];
	auto End = Start + n;
	auto BeginPrevSection = Start;
	u8*  Write = Start;
	u8*  LastRead = Start;
	
	for (u8* Curr = Start; Curr < End; Curr++ ) {
		u8 C = *Curr;
		if (C == Prev)
			continue;
			
		int PrevLength = (int)(Curr - BeginPrevSection);
		Prev = C;

		if (CanUseLength(PrevLength, x) and TF.FlipThisBit(Prev)) {
			App->Stats.BitsRandomised += PrevLength;
			if (Active) {
				while (LastRead < BeginPrevSection)
					*Write++ = *LastRead++;
				LastRead = Curr; // delete previous section
			}
		}
		
		BeginPrevSection = Curr;
	}
	
	while (LastRead < End)
		*Write++ = *LastRead++;
	
	return (int)(Write - Start);
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


static void PerfectBitDebias (u8* Start, int n, GenApproach* App) {
	auto TotalBits = BitCount(Start, n)>>3;
	int Offness = TotalBits - (n/2);
	int RandBitsNeeded = Log2i(n - 1);
	bool Active = !App->IsSudo();

	App->Stats.BitsRandomised += abs(Offness);
	u64 V2 = Seed(App, Offness);		
	
	for (int C = 0; Offness and C < 64*1024; C++ ) {
		u64 Rand = V2 = uint64_hash(V2);
		for (int r = 64; Offness and r > RandBitsNeeded; r -= RandBitsNeeded) {
			u64 i = (1<<RandBitsNeeded) - 1;
			i &= Rand;
			Rand >>= RandBitsNeeded;
			if (!Active or pdb(Start, (int)i, n, Offness))
				Offness += 1 - 2*(Offness > 0);
		}
	}
}


static int Do_Histo (BookHitter& B, u8* Start, int n, bool Log) {
	if (n==9) DebugPrintBuff(Start, n); // stop strip
	if (Log) {
		Histogram H2 = CollectHistogram(Start, n);
		DrawHistogram(B, H2, n, "");
	}
	
	if (AllowDebiaser) {
		Histogram H = CollectHistogram(Start, n);
		for (int i = BarCount - 1; i >= 1; i--)
			n = DebiasSectionsOfLength(H, Start, n, i, B.App);
	}

	PerfectBitDebias(Start, n, B.App);
	
	if (Log) {
		Histogram H2 = CollectHistogram(Start, n);
		DrawHistogram(B, H2, n, "p");
	}
	return n;
}


static u8* VonSub(u8* Read, u8* Write, int n) {
	for_(n) {
		u8 A = *Read++;
		if (A != *Read++)
			*Write++ = A;
	}
	return Write;
}


static int Do_Vonn (u8* Start, int n) {
	n >>= 1;
	u8* Write = VonSub(Start, Start, n);
	return (int)(Write - Start);
}


static int DoBytesToBits (u8* Bytes, int n, u8* Bits) {
	for_(n) {
		u32 c = Bytes[i];
		FOR_(oof, 8)
			*Bits++ = ((c>>oof)&1)*255;
	}
	
	return n*8;
}

static int DoBitsToBytes (BookHitter& B, u8* WorkSpace, int n) {
#if DEBUG
	auto Orig = CopyBytes(WorkSpace, n);
#endif

	auto nSmall = n / 8;
	for_(nSmall) {
		int j = i<<3;
		int oof = (WorkSpace[j] & 0x01) | (WorkSpace[j+1] & 0x02) | (WorkSpace[j+2] & 0x04) | (WorkSpace[j+3] & 0x08) | (WorkSpace[j+4] & 0x10) | (WorkSpace[j+5] & 0x20) | (WorkSpace[j+6] & 0x40) | (WorkSpace[j+7] & 0x80);
		WorkSpace[i] = oof;
	}

#if DEBUG
	// need to test it works...
	ByteArray RoundTrip(n);
	DoBytesToBits(&WorkSpace[0], nSmall, &RoundTrip[0]);
	for_(nSmall*8)
		if (RoundTrip[i] != Orig[i])
			debugger;
#endif
	
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

	int n = B.Space();
	u8* Start = B.Extracted();
	
	n = DoModToBit			(B, Start, Mod, n);
	n = DoXorShrink			(Start, 16, n); // 16 seems good?
	
	if (!B.App->IsSudo()) {
		n = Do_Vonn			(Start, n);
		if (n < 128) return;
	} else {
		n = (float)n * 0.23f; // sudo is just for comparison! want fair data-size to compare with.
	}

	if (Debias)
		n = Do_Histo		(B, Start, n, Log);
	n = DoBitsToBytes		(B, Start, n);
	B.App->Stats.Length = n;
}

