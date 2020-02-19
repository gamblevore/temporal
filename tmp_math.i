

int Sign(int x) {
	if (x > 0)
		return 1;
	if (x < 0)
		return -1;
	return 0;
}


int Log2i(u32 i) {
	return 32-__builtin_clz(i);
}


float Betweenness(float x, float Low, float High) {
	return (x - Low) / (High - Low);
}


float Interp(float x, float LowVal, float HighVal) {
	return LowVal + x * (HighVal - LowVal); 
}


u64 FracShift(int s, int sh) {
	if (sh < 0) debugger;
	if (s < 0)  return 0;
	return ((((u64)s) * 0x80000000u) >> sh);
}


u64 PosShift(int s, int sh) {
	if (s < 0) return 0;
	u64 i = s;
	return (sh >= 0) ? (i << sh) : 0;
}


u64 HistoCount(int N, int X) {
	int n = 1 + N - X;
	return PosShift(1ul, n-1ul) + PosShift(n-2ul, n-3ul);
}


float HistoProbSlot(int N, int X) {
	// An ass-ton of logic hidden here.
	// We avoid directly calculating:
	//      ((1<<(n-1)) + ((n-2)<<(n-3)))   /  (1<<n)
	// because n is around 65536. (1<<n) lol.
	// This equality: (1<<a)/(1<<b) == (1<<(a-b))
	// brings (a-b) into reasonable range, and removes a divide!
	// because (a-b) is always negative for us,
	// we right-shift instead, using fixed-point

	if (X > N  or  N <= 0  or  X <= 0) return 0;
	
	u64 CountA = FracShift(1, X);
	u64 CountB = FracShift(N - X - 1, X + 2);
	double P2 = (CountA + CountB);

	P2 /= (double)(0x80000000u);
	return P2;
}



struct BitSections;
struct BitView {
	// just a nicer way to read/write bits from a string!
	u32 Length; // in bits
	u32 Pos;    // also in bits
	u8  Tmp;
	u8* Data;
	
	u32 BitCount() {
		int Result = 0;
		u64* Oof = (u64*)Data;
		u64* End = (u64*)(Data + ByteLength());
		while (Oof < End)
			Result += __builtin_popcountll(*Oof++);
		return Result;
	}

	bool operator [](int i) {
		u32 BitMask = 1 << (i & 7);
		u32 BytePos = i >> 3;
		return Data[BytePos] & BitMask;
	}
	void Set(int i, bool b) {
		u8 D = Data[i >> 3];
		u8  Mask = 1 << (i & 7);
		D = (D &~ Mask) | (Mask*b);
		Data[i >> 3] = D;
	}
	bool Read() {
		return self[Pos++];
	}
	void Write(bool b) {
		int i = Pos++;
		int p = i & 7;
		Tmp |= b << p;
		if (p == 7) {
			Data[i >> 3] = Tmp;
			Tmp = 0;
		}
	}
	bool Active() {
		return Pos < Length;
	}
	void FinishWrite() {
		int LeftOver = Pos % 8;
		if (LeftOver)
			Data[Pos>>3] = Tmp;
		Length = Pos;
		Pos = 0;
	}
	u32 ByteLength() {
		return Length/8;
	}
	operator void*() {
		return (void*)Active();
	}
	BitView(u8* d, u32 ByteLength) {
		Data = d; Length = ByteLength*8; Pos = 0; Tmp = 0;
	}
	BitSections AsBytes();
	BitSections Convert (u8* Write);
};


struct BitSections {
	u32 Length;
	u32 BitLength;
	u32 Pos;
	u8* Data;
		
	u8 operator [](int i) {
		return Data[i];
	}
	void Set(int i, u8 b) {
		Data[i] = b;
	}
	u8 Read() {
		return self[Pos++];
	}
	void WriteSub(u8 b) {
		Set(Pos++, b);
	}
	int Write(int Count) {
//		BitLength += Count;
		while (1) {
			int ToWrite = std::min(Count, 255);
			Count -= ToWrite; 
			WriteSub(ToWrite);
			if (!Count) return 0;
			WriteSub(0); // align
		}
	}
	
	bool Active() {
		return Pos < Length;
	}
	operator void*() {
		return (void*)Active();
	}
	void FinishWrite() {
		Length = Pos;
		Pos = 0;
	}
	BitSections(u32 OriginalBitLength, u8* d) {
		Data = d; Length = 0; Pos = 0; BitLength = OriginalBitLength;
	}

	BitView AsBits() {
		BitView Result = {Data, Length};
		return Result;
	}
	
	BitView Convert (u8* Write) {
		BitView W = {Write, 0};
		
		bool B = false;
		while (self) {
			int Count = Read();
			FOR_(j, Count)
				W.Write(B);
			B = !B;
		}
		
		W.FinishWrite();
		Pos = 0;
		return W;
	}
};


BitSections BitView::AsBytes() {
	BitSections Result = {Length, Data};
	return Result;
}


BitSections BitView::Convert (u8* Write) {
	BitSections Result = {Length, Write};
	int Count = 0;
	bool Prev = self[0];
	if (Prev)
		Result.Write(0); // start with 0 false bits, as bits alternate false/true always
	
	while (self) {
		if (Read() != Prev) {
			Prev = !Prev;
			Count = Result.Write(Count);
		}
		Count++;
	}

	Count = Result.Write(Count);
	Result.FinishWrite();
	Pos = 0;
	return Result;
}

