


struct FunWriter {
	// absolutely no point to this class! 
	// I did have a need originally... thats why I made it
	u8*			Output;
	u8*			OutEnd;
	
	u8 Curr() {
		return *Output;
	}
	void operator << (u8 c) {
		*Output++ = c;
	}
	FunWriter(u8* Dest, int Space) {
		Output = Dest;
		OutEnd = Dest + Space;
	}
	operator void*() {
		return (void*)(Output < OutEnd);
	}
};


#pragma GCC push_options // too slow to even debug !
#pragma GCC optimize ("-O3")
struct BitCombiner {
	u32 	True[64];
	u64		RawValue;
	u32		Count;
	bool	Vote;
	
	void operator << (u64 Rnd) {
		RawValue ^= Rnd;
		if (!Vote)
			return;
		u64 C = 1;
		Count++;
		u32* T = &True[0];
		while (Rnd) {
			*T += (bool)(Rnd&C);
			Rnd &=~ C;
			C <<= 1;
			T++;
		}
	}
	
	u64 Result() {
		if (!Vote)
			return RawValue;

		if (~Count&1)
			debugger; // must be odd!
		u64 V = 0;
		u32 False = Count / 2;
		for_(64) {
			V |= (((u64)(True[i] > False))<<i);
		}
		return V;
	}
};
#pragma GCC pop_options


string MoreSteve = UnHexString("00649292924c0020fc22220000fe92929282001c2a2a2a1a00f8040204f800000000000000122a2a2a24007e8888887e003905063c0000649292924c00000066660000000000000000fe02020202001c2a2a2a1a0020fc222200000000000000003e2018201e001c2a2a2a1a0000000000000020fc222200003e10202010001c2a2a2a1a001c2222243e0020fc222200000000000000003e2018201e003905063c0000122a2a2a24001c2a2a2a1a000080fc020200107e909000000000000000001c2222243e00122a2a2a2400000000000000007c820000004080408000003e2018201e007c8282827c003e1020201000fe9090986600fe929292820040804080000000827c0000000006060000");

static void XorRetro(u64* Oofers, FunWriter FW) {
	auto P = MoreSteve.c_str();
	auto PN = MoreSteve.length();
	
	while (FW) {
		BitCombiner yeet = {};
		// yeet.Vote = true; // slow...
		int N = RetroCount - yeet.Vote;  
		for_(N) {
			u64 Next = uint64_hash(Oofers[i]);
			Oofers[i] = Next;
			yeet << Next;
		}
		auto Oof = yeet.Result();
		
		for (int i = 0; (i < 8) and FW; i++) {
			u8 B = P[i%PN];
			FW << (B^Oof);
			Oof >>= 8;
		}
	}
}


static BitView Do_Vonn (BookHitter& B, BitView R) {
	if (B.App->IsSudo()) {
		R.Length = (float)(R.Length) * 0.23f;
		return R; // want fair data-size to compare against sudo.
	}

	BitView W = {R.Data, 0};
	while (R) {
		bool A = R.Read();
		if (A != R.Read())
			W.Write(A);
	}

	W.FinishWrite();
	return W;
}


Ooof BitView DoXorShrinkBytes (BitView Bits, int Shrink) {
	auto nSmall = Bits.Length / Shrink;
	auto W = Bits.AsBytes(); nSmall /= 8;
	
	for_(nSmall) {
		int Oof = 0;
		FOR_ (x, Shrink)
			Oof = Oof xor W[i*Shrink + x];
		W.Write(Oof);
	}
	
	W.FinishWrite();
	return W.AsBits();
}


Ooof BitView DoXorShrink (BitView Bits, int Shrink) {
	auto nSmall = Bits.Length / Shrink;
	
	for_(nSmall) {
		int Oof = 0;
		FOR_ (x, Shrink)
			Oof = Oof xor Bits[i*Shrink + x];
		Bits.Write(Oof);
	}
	
	Bits.FinishWrite();
	return Bits;
}


static BitView DoModToBit (BookHitter& B, int Mod, int n) {
	auto Data = B.Out();
	BitView biv = {B.Extracted(), 0};

	if (Mod) {
		u32 Mul = (256 / Mod); // Mul does help.
		Mul += (~Mul&1);
		for_(n)
			biv.Write(((Data[i] % Mod)*Mul) & 1);
	} else {
		for_(n) {
			u32 V = Data[i]; // multiple bits
			biv.Write((V & 1)^((V&2)>>1));
		}
	}	
	
	biv.FinishWrite();
	return biv;
}


static BitView BuildOofers(uSample* In, u64* Oofers) {
	BitView Result = {(u8*)Oofers, RetroCount*8}; 

	for_(RetroCount) {
		u64 Oof = 0;
		FOR_(b, 8)
			Oof = (Oof << 8) ^ (*In++&255); // prettier colors?
//		Oof = rotl(Oof, 8) ^ (*In++&255);
//		Oof = rotl(Oof, 8) ^ (*In++);
		*Oofers++ = Oof; 
	}
	
	return Result;
}


static void ExtractRetro (BookHitter& B, bool IsFirst) {
	auto Bits = BuildOofers(&B.Samples[0], B.OoferExtracted());	
	B.App->Stats = {}; // stats is written to by do_histo, so clear here.
	B.App->Stats.Length = Bits.ByteLength();

	if (IsFirst and B.LogFiles() and !B.NoImgs()) {
		B.TryLogApproach("p");
		
		u32 DummyLength = 1<<14; // should have more than that many bytes avail in samples.
		u8* DummyDest = (u8*)(&B.Samples[0]);
		BitView BV = {DummyDest, DummyLength};
		
		FunWriter FW(BV.Data, BV.ByteLength());
		XorRetro(B.OoferExtracted(),  FW);
		Shrinkers Retro = {};
		Retro.Log = 1;
		Do_Histo(B, BV, Retro);
		WriteColorImg(BV.Data, BV.ByteLength(), B.App->Png());
	}
}


static void ExtractRandomness (BookHitter& B,  int Mod,  Shrinkers Flags) {
	B.App->Stats = {}; // stats is written to by do_histo, so clear here.
	if (!B.LogFiles()) 
		Flags.Log = false;

	if (B.ChaosTesting()) {
		Flags.Vonn = 0;
		Flags.PreXOR = 0;
	}

	auto bits = DoModToBit	(B, Mod, B.GenSpace());

	if (Flags.PreXOR)
		bits  = DoXorShrink	(bits, Flags.PreXOR); // 16 seems good?

	if (Flags.Vonn) 
		bits  = Do_Vonn		(B, bits);

	bits = Do_Histo			(B, bits, Flags);

	int N = bits.ByteLength();
	B.App->Stats.Length = N;
}

