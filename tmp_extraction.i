

u64 Random64 () {
	static u64 x = 123;
	x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
	x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
	x = x ^ (x >> 31);
	return x;
}


static int DoModToBit (BookHitter& P, u8* Start, int Mod, int n) {
	auto Data = P.Out();
	u8* Write = Start;
	u32 Cap = 256 - (256 % Mod);
	if (P.App->Gen->Type) Cap = -1;
	FOR_ (i, n) {
		u32 V = Data[i]; 
		if (V > Cap)
			V = (u32)Random64();
		V = (V % Mod) * (256/Mod); // no idea why im multiplying.
		*Write++ = (V % 2)*255;
	}
	
	return (int)(Write - Start);
}


struct Histo {
	u16 Value[2];
};


static int DoDebias (u8* Start, int n) {
	Histo TrueFalse;
	Histo Histogram[17];
	bool Prev = Start[0];
	int Length = 0;
	for_(n) {
		bool b = Start[i];
		TrueFalse.Value[b]++; // Collect true/false separately?
		if (b == Prev) {
			Length++;
		} else {
			Length = std::min(Length, 16);
			Histogram[Length].Value[Prev]++;
			Prev = b;
			Length = 1;
		}
	}
	return n;
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


static int ExtractRandomness (BookHitter& P) {
	int n = P.Space();
	n = std::min(n, P.Time.Measurements);
	u8* Start = P.Extracted();
	n = DoModToBit			(P, Start, P.App->Mod, n);
	n = DoDebias			(Start, n);
	n = DoXorShrink			(Start, 16, n);
	n = DoBitsToBytes		(Start, n);
	return n;
}

