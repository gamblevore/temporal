

struct ChanceShuffler {
	u64			Value;
	float		Chance;
	float		MissingChance;
	u8			Position;
	
	u64 CreateValue() {
		int N = (std::min(Chance+MissingChance, 1.0f) * 64.0f) + 0.5;
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
		Chance = std::min(C, 1.0f);
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
struct HistogramConf {
	float		Values[BarCount];
	int			NMax;
	
	HistogramConf (int n) {
		NMax = n;
		for_(BarCount)
			Values[i] = HistoProb(n, i);
	}
};


ref(HistogramConf) OldHisto;
struct Histogram {
	Histo				Slot[BarCount];
	int					LostBits;
	ref(HistogramConf)	Expected;
	
	Histogram (int n) {
		LostBits = 0;
		SetConf(n);
	}

	Histo& operator[] (int i) {
		return (Slot)[i];
	}
	
	void SetConf(int n) {
		if (OldHisto and OldHisto->NMax == n) {
			Expected = OldHisto;
		} else {
			Expected = New2(HistogramConf, n);
			OldHisto = Expected;
		}
	}
	
	void Add(int Length, bool Prev) {
		if (Length >= BarCount) {
			int LengthMax = BarCount - 1;
			LostBits += (Length - LengthMax);
			Length = LengthMax;
		}
		
		(*this)[Length][Prev] += 1;
	}
	
	void Reset () {
		for_( BarCount )
			Slot[i] = {};
	}
	
	Chances FlipBits(int x) {
  // If we have 10 too many, within 100, we will eliminate 1/10. in any random order
		float Lim = 0;
		if (x < BarCount-1)
			Lim = Expected->Values[x] + Interp(Betweenness(x, 1, 11), 0.025, 0.5);
		Histo TrueAndFalse = (*this)[x];
		Chances Result;
		for_(2) {
			float Occur = TrueAndFalse[i];
			float Extra = std::max(Occur - Lim, 0.0f);
			float Chance = Occur > (1.0/2048.0) ? Extra/Occur : 0; 
			Result.Shuff[i].Init(Chance);
		}
		return Result;
	}
};


static void HistogramVerify (Histogram& H) {
	// Verify histogram
	test(H[0][0] + H[0][1] == H.Expected->NMax);
	int Total = H.LostBits;
	for (int i = 1; i < BarCount; i++)
		Total += (H[i][0] + H[i][1])*i;

	test(Total == H.Expected->NMax);
}


static Histogram CollectHistogram (u8* Start, int n) {
	Histogram H(n);
	int Length = 0;
	bool Prev = Start[0];
	for_(n) {
		bool b = Start[i];
		H[0][b]++;							// Collect true-false separately.
		if (b != Prev) {
			H.Add(Length, Prev);
			Prev = !Prev;
			Length = 0;
		}
		Length++;
	}
	H.Add(Length, Prev);
	HistogramVerify(H);
	return H;
}


[[maybe_unused]] static void BitsCollectHistogram (Histogram& H, u64 Start, int n) {
	int Length = 0;
	bool Prev = Start&1;
	for_(n) {
		bool b = Start&(1<<i);
		H[0][b]++; // collect true-false separately.
		if (b != Prev) {
			H.Add(Length, Prev);
			Prev = !Prev;
			Length = 0;
		}
		Length++;
	}
	H.Add(Length, Prev);
}


static void PrintProbabilities() {
	printf("\n\nProbability Calculation\n\n");
	int N = 64*1024;
	for (int X = 1; X < BarCount; X++) {
		float P = HistoProb(N, X);
		if (!P) break;
		if (X!=BarCount-1 and X>1)
			printf(",  ");
		printf("%i: ", X);
		printf("%.3f%%", P*100);
	}
	printf("\n");
}
