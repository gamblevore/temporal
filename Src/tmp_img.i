

static void WriteImg (u8* Data, u32 N, int Comp, string Name) {
	stbi_write_png_compression_level = 9;
	u32 W = sqrt(N);
	errno = 0;
	stbi_write_png(Name.c_str(), W, W, Comp, Data, W*Comp);
	if (errno) {
		string c = GetCWD();
		fprintf(stderr, "Can't write png to: '%s' %s. (cwd='%s')\n", Name.c_str(), c.c_str(), strerror(errno));
		errno = 0;
	}
}



Ooof void WriteBitsImg (u8* Data, u32 N, string Name) {
	BitView V = {Data, N};
	ByteArray Img2 = ByteArray(V.Length+100, 0);
	while (V) {
		int i = V.Pos;
		Img2[i] = 255 * V.Read();
	}

	WriteImg(Data, N, 1, Name);
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
	N = min(N, 40000u);
	ByteArray G = ByteArray(N*4, 0);
	ColoriseSamples(Data, &G[0], N);
	WriteImg(&G[0], N, 4, Name);
}

