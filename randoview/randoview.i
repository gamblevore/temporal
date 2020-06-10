
BookHitter* Steve;

struct Pixel {
	u8 R;
	u8 G;
	u8 B;
	u8 A;
	u32 Gray() {
		return (R + G + B);
	}
};
static Pixel PixelBadPixel;

struct RawDrawInfo {
	int w; int h;
	Pixel* Pixels;
	int BytesPerPixel;
	int Stride; // in case of working a section of an img.

	static const int CharWidth = 6; 
	static const int CharHeight = 9; 
	
	bool Load(const char* Name) {
		string Data = ReadFile(Name);
		return LoadStr(Data, Name);
	}
	
	bool LoadEmpty(int W, int H) {
		if (w!=W or H!=h) {
			free(Pixels);
			w = W; h = H;
		
			Pixels = (Pixel*)calloc(w*h, sizeof(Pixel));
			BytesPerPixel = 4;
			Stride = BytesPerPixel * w / sizeof(Pixel);
		}
		return Pixels;
	}
	
	bool LoadStr(string Data, const char* Name) {
		Pixels = (Pixel*)stbi_load_from_memory((u8*)Data.c_str(), (int)Data.length(), &w, &h, &BytesPerPixel, sizeof(Pixel));
		Stride = BytesPerPixel * w / sizeof(Pixel);
		if (!Pixels) {
			printf( "Can't load image: '%s'\n", Name);
		}
		return Pixels;
	}
	
	Pixel* Get(int x, int y) {
		if (InRange(x,w) and InRange(y,h))
			return Pixels + x + ((-y+h-1)*Stride);
		return &PixelBadPixel;
	}

	void DrawChar(int C, RawDrawInfo& Where, int DrawX, int DrawY) {
		FOR_ (y, CharHeight) {
			FOR_ (x, CharWidth) {
				Pixel* D = Where.Get(x+DrawX, DrawY+y);
				Pixel* R = self.Get(x+C*CharWidth, y);
				*D = *R;
			} 
		} 
	}
	
	void DrawTo(RawDrawInfo& Where, int DrawX=0, int DrawY=0) {
		FOR_ (y, h) {
			FOR_ (x, w) {
				Pixel* D = Where.Get(x+DrawX, DrawY+y);
				Pixel* R = self.Get(x, y);
				*D = *R;
			} 
		} 
	}
	void DrawText(const char* Str, RawDrawInfo& Where, int x=0, int y=0) {
		if (Where.Pixels and Pixels)
			for (int i = 0; Str[i]; i++)
				DrawChar(Str[i], Where, x + i*CharWidth, y);
	}
};


 



struct KeyHandler {
	SDL_Event event;
	bool IsRaw;
	bool IsBG;
	double FrameLength;
	std::chrono::high_resolution_clock::time_point		LastTime;
	std::chrono::high_resolution_clock::time_point		ChannelTime;

	
	KeyHandler() {
		FrameLength = 1.0/60.0;
		IsRaw = true;
		ChannelTime = now();
	}
	
	bool Running() {
		while (SDL_PollEvent(&event))
			if (!CheckEvent())
				return false;
		return true;
	}
	
	std::chrono::high_resolution_clock::time_point now() {
		return std::chrono::high_resolution_clock::now();
	}
	
	void FrameLimit() {
		auto F = FrameLength;
		if (IsBG)
			F = 1.0/1.0;
		while ( true ) {
			auto t_now = now();
			auto Durr = std::chrono::duration_cast<std::chrono::duration<double>>(t_now - LastTime).count();
			if (Durr >= F) {
				LastTime = t_now;
				break;
			}
			SDL_Delay(1);
		}
	}
	
	bool CheckEvent() {
		auto t = event.type;
		
		if (t == SDL_APP_DIDENTERFOREGROUND or t == SDL_APP_DIDENTERBACKGROUND) {
			IsBG = (t == SDL_APP_DIDENTERBACKGROUND);
			return true;
		}


		if (t == SDL_QUIT or t==SDL_APP_TERMINATING)
			return false;
		
		if (t == SDL_WINDOWEVENT) {
			int ev = event.window.event;
			if (ev == SDL_WINDOWEVENT_CLOSE) {
				return false;
			} else if (ev == SDL_WINDOWEVENT_FOCUS_GAINED) {
				IsBG = false;
			} else if (ev == SDL_WINDOWEVENT_FOCUS_LOST) {
				IsBG = true;
			}
		} else if (t == SDL_KEYDOWN) {
			auto key = event.key.keysym.sym;
			if (key == SDLK_LEFT) {
				bh_setchannel_num(Steve, bh_config(Steve)->Channel - 1);
				ChannelTime = now();
			} else if (key == SDLK_RIGHT) {
				bh_setchannel_num(Steve, bh_config(Steve)->Channel + 1);
				ChannelTime = now();
			} else if (key == SDLK_UP) {
				IsRaw = true;
			} else if (key == SDLK_DOWN) {
				IsRaw = false;
			}
		}
	
		return true;
	}
	
};
