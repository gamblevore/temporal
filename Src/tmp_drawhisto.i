

static void DrawRect(u8* Image, int ImageWidth, int ImageHeight, int RectX, int RectWidth, int RectY, int RectHeight, int Value) {
	Image += RectY*ImageWidth;
	int RectXEnd = min(RectX + RectWidth,  ImageWidth );
	int RectYEnd = min(RectY + RectHeight, ImageHeight);
	for (int y = RectY; y < RectYEnd; y++)
		for (int x = RectX; x < RectXEnd; x++)
			Image[(ImageHeight-y)*ImageWidth + x] = Value;

	if (RectY+RectHeight > ImageHeight) { // overflow...
		for (int x = RectX; x < RectXEnd; x++) {
			Image[(0)*ImageWidth + x] = ((x+1) & 1)*Value;
			Image[(1)*ImageWidth + x] = ((x+0) & 1)*Value;
		}
	}
}


static float HScale(float Value, float Height, float Expected) {
	Expected = std::round(Expected);
	float Answer = 1.0;
	if (!Expected and !Value) {
		;
	} else if (!Expected and Value) {
		Answer = Value;
	} else {
		Answer = Value/Expected;
	}
	return (Height * Answer) / 1.5; 
}


static void DrawHistogramSub (GenApproach* App, Histogram& H, float N, string ExtraName) {
	int BarWidth = 7; // px
	int BarGap = 2;
	int MyBarCount = 8;   MyBarCount = min(MyBarCount, BarCount);
	
	int TotalWidth = (BarWidth * MyBarCount*2) + (BarGap*(MyBarCount-1));
	int TotalHeight = TotalWidth; // why not.
	int Size = TotalHeight*TotalWidth;

	ByteArray Data(Size*2, (u8)0); // stb_write has trouble otherwise... no idea why!
	u8* const Start = &Data[0];

	float Scale = (float)TotalHeight;
	int x = 0;
	
	FOR_(b, MyBarCount) {
		float* Values = H[b].Value;
		float Exp = H.Expected[b];
		DrawRect(Start, TotalWidth, TotalHeight, x, BarWidth, 0, HScale(*Values++, Scale, Exp), 128);
		x += BarWidth;
		DrawRect(Start, TotalWidth, TotalHeight, x, BarWidth, 0, HScale(*Values++, Scale, Exp), 255);
		x += BarWidth;
		x += BarGap;
	}

	string name = GenApproach::FileName_(App, ExtraName + "h");
	WriteImg(Start, Size, 1, name);
}


static void DrawHistogram (BookHitter& B, Histogram& H, float N, string ExtraName) {
	if (B.NoImgs()) return;
	DrawHistogramSub(B.App, H, N, ExtraName);
}
