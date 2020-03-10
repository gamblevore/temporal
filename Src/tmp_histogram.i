

struct ChanceShuffler {
	u64			Value;
	float		Chance;
	float		MissingChance;
	u8			Position;
	
	u64 CreateValue() {
		int N = (min(Chance+MissingChance, 1.0f) * 64.0f) + 0.5;
		MissingChance = Chance - ((float)N / 64.0f);

		u64 V = (N<64) ? (1ul<<N) - 1 : -1;
		if (!V or V==-1) return V;
		
		for (int Pos1 = 0; Pos1 < 64;) {
			u64 Rand = Random64();
			for (int i = 0; i < 10 and Pos1 < 64; i++) {
				u64 i1 = (1ul<<(Pos1++));
				u64 i2 = (1ul<<(Rand & 63u)); Rand >>= 6;

				bool b1 = V & i1;
				bool b2 = V & i2;
				V &= ~(i1|i2);
				V |= (b1*i2) | (b2*i1);
			}
		}
				
		return V;
	}

	void Reset() {
		Position = 0;
		Value = CreateValue();
	}

	void Init(float C) {
		Chance = min(C, 1.0f);
		MissingChance = 0;
		Reset();
	}

	bool FlipThisBit() {
		if (Position>=64)
			Reset();
		return Value & (1 << Position++);
	}
};


struct Chances {
	ChanceShuffler Shuff[2];
	bool FlipThisBit(bool b) {
		return Shuff[b].FlipThisBit();
	}
	bool NoNeed() {
		return !Shuff[0].Chance and !Shuff[1].Chance;
	}
};


struct Histo {
	float Value[2];
	Histo() {
		Value[0] = 0;
		Value[1] = 0;
	}
	float& operator[] (int i) {
		return (Value)[i];
	}
};


#define BarCount 18

struct Histogram {
	Histo				Slot[BarCount];
	float				Expected[BarCount];
	int					LostBits;
	int					HalfIndex;
	
	Histogram () {
		HalfIndex = 0;
		LostBits = 0;
	}
	
	int BitCount() {
		return self[0][0] + self[0][1];
	}
	
	void FillStats() {
		int n = BitCount();
		for (int i = BarCount - 1; i >= 1; i--) {
			Expected[i] = HistoProbSlot(n, i);
			if (Expected[i] < 0.5)
				HalfIndex = i;
		}
		Expected[0] = ((float)n)*0.5f;
	}

	Histo& operator[] (int i) {
		return (Slot)[i];
	}
		
	void Add(int Length, bool B) {
		if (Length) {
			self[0][B] += Length;							// Collect true-false separately.
			if (Length >= BarCount) {
				int LengthMax = BarCount - 1;
				LostBits += (Length - LengthMax);
				Length = LengthMax;
			}
			
			self[Length][B] += 1;
		}
	}
	
	void Reset () {
		for_( BarCount )
			Slot[i] = {};
	}
	
	Chances FlipBits(int x) {
  // If we have 10 too many, within 100, we will eliminate 1/10. in any random order
		float Lim = 0;
		if (x < HalfIndex)
			Lim = Expected[x] + Interp(Betweenness(x, 1, 11), 0.025, 0.5);
		Histo TrueAndFalse = self[x];
		Chances Result;
		for_(2) {
			float Occur = TrueAndFalse[i];
			float Extra = max(Occur - Lim, 0.0f);
			float Chance = Occur > (1.0/2048.0) ? Extra/Occur : 0; 
			Result.Shuff[i].Init(Chance);
		}
		return Result;
	}
};


static void HistogramVerify (Histogram& H) {
// Verify histogram
	int Found = H.BitCount();
	int Total = H.LostBits;
	for (int i = 1; i < BarCount; i++)
		Total += (H[i][0] + H[i][1])*i;

	test(Total == Found);
}


static Histogram CollectHistogram (BitSections X) {
	Histogram H;

	for_(X.Length)
		H.Add(X[i], i&1);
	
	H.FillStats();
	HistogramVerify(H);
	return H;
}


Ooof void RandStatsAccum (RandTest& RT,  Histogram& H,  u8* Addr,  u32 Len) {
	for_(Len)
		RT.add_byte(Addr[i]);

	BitView V = {Addr, Len};
	ByteArray D(Len*8+1, 0);
	auto X = V.Convert(&D[0]);

	for_(X.Length)
		H.Add(X[i], i&1);
}


static float HistoInputRandoOne(Histogram& H, int i, bool b) {
	if (i==0) return 0;
	float Expected = H.Expected[i];
	float Occur = H[i][b];
	float Diff = fabsf(Expected - Occur);
	float Int = 0;
	float IgnoredFr = modff(Diff, &Int);
	float Allowed = IgnoredFr - 0.5;
	if (Allowed > 0)
		Diff -= Allowed; // discontinuous
		
	float Badness = (Diff*Diff) / Expected;
	
	return Badness / 1000.0;
	return sqrt(Badness) / 500.0;
}


static float HistoInputRandomness(Histogram& H) {
	H.FillStats();
	float Result = 0;
	for_(BarCount-1) {
		Result += HistoInputRandoOne(H, i+1, true);
		Result += HistoInputRandoOne(H, i+1, false);
	}
	return Result;
}


Ooof void PrintProbabilities() {
	printf("\n\nProbability Calculation\n\n");
	int N = 64*1024;
	int XEnd = 19;
	for (int X = 1; X < XEnd; X++) {
		float P = HistoProbSlot(N, X);
		if (!P) break;
		if (X!=XEnd-1 and X>1)
			printf(",  ");
		printf("%i: ", X);
		printf("%.3f%%", P*100);
	}
	printf("\n");
}



Ooof void FullRandomnessDetect (GenApproach& R,  u8* Addr,  u32 Len) {
	BitView V = {Addr, Len};
	ByteArray D(Len*8+1, 0);
	auto Sections = V.Convert(&D[0]);
	Histogram H = CollectHistogram(Sections);
	R.Stats.Hist = HistoInputRandomness(H);
	DetectRandomness_(R, Addr, Len);
}

