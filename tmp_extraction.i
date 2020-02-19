


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
	int n = B.Space();
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


static void ExtractRandomness (BookHitter& B,  int Mod,  bool Debias,  bool WantRaw) {
	B.App->Stats = {}; // stats is written to by do_histo, so clear here.

	WantRaw = WantRaw or B.ChaosTesting();

	auto bits = DoModToBit	(B, Mod);

	if (!WantRaw)
		bits  = DoXorShrink	(bits, 16); // 16 seems good?

	if (!WantRaw) 
		bits  = Do_Vonn		(B, bits);

	
	Debias = Debias and !WantRaw;
	bits = Do_Histo			(B, bits, B.LogOrDebug(), Debias);

	B.App->Stats.Length = bits.ByteLength();
}

