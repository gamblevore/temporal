

static void XorRetro(u64* Oofers, u8* Dest, int N) {
	u8* Write    = Dest;
	u8* WriteEnd = Dest + N;
	
	while (Write < WriteEnd) {
		u64 Oof = 0;
		for_(RetroCount) {
			u64 Next = uint64_hash(Oofers[i]);
			Oofers[i] = Next;
			Oof ^= Next;
		}
		
		for (int i = 0; i < 8 and Write < WriteEnd; i++) {
			* Write++ = Oof & 255;
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


static BitView DoModToBit (BookHitter& B, int Mod) {
	int n = B.GenSpace();
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


static BitView BuildOofers(u32* In, u64* Oofers) {
	BitView Result = {(u8*)Oofers, RetroCount*8}; 

	for_(RetroCount) {
		u64 Oof = 0;
		FOR_(b, 8)
			Oof = (Oof << 8) ^ (*In++&255); // prettier colors?
//		Oof = rotl(Oof, 8) ^ (*In++&255);
		*Oofers++ = Oof; 
	}
	
	return Result;
}


static void ExtractRetro (BookHitter& B, bool IsFirst) {
	auto Bits = BuildOofers(&B.Samples[0], B.OoferSpace());	
	B.App->Stats = {}; // stats is written to by do_histo, so clear here.
	B.App->Stats.Length = Bits.ByteLength();

	if (IsFirst and B.LogOrDebug() and !B.NoImgs()) {
		B.TryLogApproach("p");
		
		u32 DummyLength = 1<<14; // should have more than that many bytes avail in samples.
		u8* DummyDest = (u8*)(&B.Samples[0]);
		BitView BV = {DummyDest, DummyLength};

		XorRetro(B.OoferSpace(),  BV.Data,  BV.ByteLength());
		Shrinkers Retro = {};
		Retro.Log = 1;
		Do_Histo(B, BV, Retro);
		WriteColorImg(BV.Data, BV.ByteLength(), B.App->FileName(""));
	}
}


static void ExtractRandomness (BookHitter& B,  int Mod,  Shrinkers Flags) {
	B.App->Stats = {}; // stats is written to by do_histo, so clear here.
	if (!B.LogOrDebug()) 
		Flags.Log = false;

	if (B.ChaosTesting()) {
		Flags.Vonn = 0;
		Flags.PreXOR = 0;
	}

	auto bits = DoModToBit	(B, Mod);

	if (Flags.PreXOR)
		bits  = DoXorShrink	(bits, Flags.PreXOR); // 16 seems good?

	if (Flags.Vonn) 
		bits  = Do_Vonn		(B, bits);

	bits = Do_Histo			(B, bits, Flags);

	int N = bits.ByteLength();
	B.App->Stats.Length = N;
}

