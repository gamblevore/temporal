

static void WriteImg (u8* Data, u32 N, string Name) {
	stbi_write_png_compression_level = 9;
	u32 W = sqrt(N);
	stbi_write_png(Name.c_str(), W, W, 1, Data, W);
}


Ooof void WriteBitsImg (u8* Data, u32 N, string Name) {
	stbi_write_png_compression_level = 9;
	BitView V = {Data, N};
	ByteArray Img2 = ByteArray(V.Length+100, 0);
	while (V) {
		int i = V.Pos;
		Img2[i] = 255*V.Read();
	}

	int W = sqrt(V.Length);
	stbi_write_png(Name.c_str(), W, W, 1, &Img2[0], W);
}


Ooof void ColoriseSamples (u8* In, u8* Out, u32 N) {
	for_(N) {
		u8 D = *In++;
		u8 DR = ((D>>0)&7)*36;
		u8 DG = ((D>>3)&7)*36;
		u8 DB = ((D>>2)&3)*85;
		Out[i*4+0] = DR;
		Out[i*4+1] = DG;
		Out[i*4+2] = DB;
		Out[i*4+3] = 255;
	}
}


Ooof void WriteColorImg (u8* Data, u32 N, string Name) {
	// just 1 byte per color... makes more sense.
	ByteArray G = ByteArray(N*4, 0);
	ColoriseSamples(Data, &G[0], N);
	int W = sqrt(N);
	stbi_write_png(Name.c_str(), W, W, 4, &G[0], W*4);
}

