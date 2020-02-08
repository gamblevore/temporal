

static void DrawRect(u8* Image, int ImageWidth, int ImageHeight, int RectX, int RectWidth, int RectY, int RectHeight, int Value) {
	Image += RectY*ImageWidth;
	int RectXEnd = std::min(RectX + RectWidth,  ImageWidth );
	int RectYEnd = std::min(RectY + RectHeight, ImageHeight);
	while (RectY < RectYEnd) {
		for (int x = RectX; x < RectXEnd; x++)
			Image[(ImageHeight-RectY)*ImageWidth + x] = Value;
		RectY++;
	}
}


static float HistogramHighest (Histogram& H) {
	int Highest = 0;
	for_(BarCount) {
		Highest = std::max(Highest, (int)H[i][0]);
		Highest = std::max(Highest, (int)H[i][1]);
	}
	float Hi = Highest;
	return std::min(Hi*1.1, 64.0*1024.0);
}


static void DrawHistogram (BookHitter& B, Histogram& H, string ExtraName) {
	int BarWidth = 10; // px
	int BarGap = 2;
	int MyBarCount = 6;   MyBarCount = std::min(MyBarCount, BarCount);
	
	int TotalWidth = (BarWidth * MyBarCount*2) + (BarGap*(MyBarCount-1));
	int TotalHeight = TotalWidth; // why not.
	int Size = TotalHeight*TotalWidth;
	ByteArray Data(Size, (u8)0);
	u8* Start = &Data[0];

	float Scale = (float)TotalHeight / HistogramHighest(H);
	int x = 0;
	
	FOR_(b, MyBarCount) {
		float* Values = H[b].Value;
		DrawRect(Start, TotalWidth, TotalHeight, x, BarWidth, 0, *Values++*Scale, 128);
		x += BarWidth;
		DrawRect(Start, TotalWidth, TotalHeight, x, BarWidth, 0, *Values++*Scale, 255);
		x += BarWidth;
		x += BarGap;
	}
	
	B.CreateDirs();
	WriteImg(Start, Size, B.App->FileName(ExtraName + "h"));
}

