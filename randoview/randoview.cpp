
#pragma clang diagnostic ignored "-Wdocumentation"
#include <SDL2/SDL.h>        


#include "randoview.i"


struct FullScreenSteve {
	int w; int h;
	int FrameCount;
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_Texture* Raw;

	
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

		window = SDL_CreateWindow("Tune into Steve‘s Channels",
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w*4, h*4, SDL_WINDOW_RESIZABLE);

		renderer = SDL_CreateRenderer(window, -1, 0);
		Raw = SDL_CreateTexture(renderer, 0, SDL_TEXTUREACCESS_STREAMING, w, h);
	}

	RawDrawInfo StartFrame(SDL_Texture* T) {
		RawDrawInfo Result = {w,h};
		int BytesPerRow = 0;
		SDL_LockTexture(T, NULL, (void**)(&Result.Pixels), &BytesPerRow);
		Result.BytesPerPixel = BytesPerRow / w;
		
		if (Result.BytesPerPixel != 4 and Result.BytesPerPixel!=3) { // seems fair!
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
};


int main(int argc, char** argv) {
	Steve = bh_create();
	bh_config(Steve)->AutoReScore = false;
//	bh_config(Steve)->Log = -1;

	FullScreenSteve View = {};
	View.DetectSizes();
	View.StartSteveWindow();
	
	KeyHandler Keys;
	while (Keys.Running()) {
		bh_config(Steve)->Channel = Keys.Channel;
		auto Buff = View.StartFrame(View.Raw);
		DrawSteveFrame(Buff, Keys.IsRaw);
		Keys.FrameLimit();
		View.EndFrame(View.Raw);
	}
	
	bh_free(Steve);
	return 0;
}
