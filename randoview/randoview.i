
#include "TemporalLib.h"
#include <chrono>

BookHitter* Steve;

typedef unsigned char u8;


struct RawDrawInfo {
	int w; int h;
	unsigned char* Pixels;
	int BytesPerPixel;
};


 
void DrawSteveFrame(const RawDrawInfo& T, bool What) {
	int n = T.w * T.h;
	if (What) {
		bh_hitbooks(Steve, 0, 1);
		bh_view_colorised_samples(Steve, T.Pixels, n);
	} else if (T.BytesPerPixel == 4) {

//		n = n / 4;
// why is this not crashing? it should corrupt memory?

		static std::string s;
		s.resize(n);
		u8* S = (u8*)s.c_str();

		bh_hitbooks(Steve, S, n);
		bh_colorise_external(S, n, T.Pixels);
	} else {
		// ermm... dunno what to do.
	}
}



struct KeyHandler {
	SDL_Event event;
	u8 Channel;
	bool IsRaw;
	bool IsBG;
	double FrameLength;
	std::chrono::high_resolution_clock::time_point		LastTime;

	
	KeyHandler() {
		Channel = 1;
		FrameLength = 1.0/60.0;
		IsRaw = true;
	}
	
	bool Running() {
		while (SDL_PollEvent(&event))
			if (!CheckEvent())
				return false;
		return true;
	}
	
	void FrameLimit() {
		auto F = FrameLength;
		if (IsBG)
			F = 1.0/1.0;
		while ( true ) {
			auto t_now = std::chrono::high_resolution_clock::now();
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
		} else if (t == SDL_KEYDOWN and !event.key.repeat) {
			auto key = event.key.keysym.sym;
			if (key == SDLK_LEFT) {
				Channel--;
			} else if (key == SDLK_RIGHT) {
				Channel++;
			} else if (key == SDLK_UP) {
				IsRaw = true;
			} else if (key == SDLK_DOWN) {
				IsRaw = false;
			}
		}
	
		return true;
	}
	
};
