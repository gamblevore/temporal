
#pragma clang diagnostic ignored "-Wdocumentation"
#include <SDL2/SDL.h>        
#include "../Src/includes/stb_image.h"

#include "randoview.i"
#include "unistd.h"


struct FullScreenSteve {
	int w; int h;
	int FrameCount;
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_Texture* Raw;
	KeyHandler		Keys;
	RawDrawInfo  SmallFont;

	
	~FullScreenSteve() {
		SDL_DestroyTexture(Raw);
		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(window);
		SDL_Quit();
	}

	void DetectSizes() {
		int bytes = bh_view_colorised_samples(NULL, NULL, NULL);
		int Pixels = bytes / 4;
		int SQ = sqrt(Pixels);
//		asm("int3");
		w = SQ;
		h = SQ;
	}
	
	void StartSteveWindow() {
		SDL_Init(SDL_INIT_VIDEO);

		window = SDL_CreateWindow("Steve‘s Crazy TV Channels",
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w*4, h*4, SDL_WINDOW_RESIZABLE);

		renderer = SDL_CreateRenderer(window, -1, 0);
		Raw = SDL_CreateTexture(renderer, 0, SDL_TEXTUREACCESS_STREAMING, w, h);
// prefered format is 372645892. gives 4 bytes per pixel... rgba.
// it should be one of the sdl_format defines, dunno which.
//		Uint32 f; int w; int h; int a;
//		SDL_QueryTexture(Raw, &f, &a, &a, &h);
		
		SmallFont.Load("resources/SmallFont.png");
	}

	RawDrawInfo StartFrame(SDL_Texture* T) {
		RawDrawInfo Result = {w,h};
		SDL_LockTexture(T, NULL, (void**)(&Result.Pixels), &Result.Stride);
		Result.BytesPerPixel = Result.Stride / w;
		Result.Stride /= 4;
		
		if (Result.BytesPerPixel != 4) { // seems fair!
			printf("wrong bytes per pixel: %i\n", Result.BytesPerPixel);
			exit(-1);
		}
		return Result;
	}
	
	void EndFrame(SDL_Texture* T) {
		SDL_UnlockTexture(T);
		SDL_Rect dstrect = {};
		SDL_GL_GetDrawableSize( window, &dstrect.w, &dstrect.h );
		SDL_RenderCopy(renderer, T, NULL, &dstrect);
		SDL_RenderPresent(renderer);
		FrameCount++;
	}


	void DrawSteveFrame(RawDrawInfo& T, bool What) {
		int n = T.w * T.h;
		bh_stats* Stats = 0;
		if (bh_config(Steve)->Channel <= 0) {
			static std::string s;
			s.resize(n);
			u8* S = (u8*)s.c_str();
			Stats = bh_hitbooks(Steve, S, n/16);
			bh_colorise_external(S, n, (u8*)T.Pixels);

		} else {
			Stats = bh_hitbooks(Steve, NULL, 1);
			bh_view_colorised_samples(Steve, (u8*)T.Pixels, n);
		}
		
		auto Durr = std::chrono::duration_cast<std::chrono::duration<double>>(Keys.now() - Keys.ChannelTime).count();
		
		if (Stats and Durr < 2.0) {
			int C = bh_config(Steve)->Channel;
			std::string S;
			S = std::to_string(C) + ": ";
			S += Stats->ApproachName;
			S += "_";
			S += std::to_string(Stats->ApproachReps);
			SmallFont.DrawText( S.c_str(), T);
		}		
	}

};


int main(int argc, char** argv) {
	Steve = bh_create();
	bh_config(Steve)->AutoReScore = false;
	bh_config(Steve)->DontSortRetro = true;

	FullScreenSteve View = {};
	View.DetectSizes();
	View.StartSteveWindow();
	
	while (View.Keys.Running()) {
		bh_config(Steve)->Channel = View.Keys.Channel;
		auto Buff = View.StartFrame(View.Raw);
		View.DrawSteveFrame(Buff, View.Keys.IsRaw);
		View.Keys.FrameLimit();
		View.EndFrame(View.Raw);
	}
	
	bh_free(Steve);
	return 0;
}


