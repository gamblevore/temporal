



#define AudioBufferCount 1024
int		Mixed[AudioBufferCount];


static int Adjust_(int Sample) {
	const int Shift = 4;
//	const int Bits = sizeof(Sample)*8;
	const int Max = 128*1024*1024;
// so what number, << 4, can overdrive?
// the thing is... we allow for 16x overdrive? or something like that?
// So anyhow... how to detect overdrive?
// let's say... we have 256. So... that means -128 to 127.
// OK.
// so that's 8 bit.
// so... now what? Let's say we had a number from 32 to -32, so that's 64. I guess... it can't be beyond 32. So... we need to check for that.
// how? god... it's so... hard. I can't figure it out :(
// the max is 2GB. OK? So... we shfted by 4. So it's 2GB>>4.
// 128K
// so... what's that?
	if (Sample >= Max) {
		return  (Max - 1) << Shift;
	} else if (Sample < -Max) {
		Sample = -Max;
	}
	return Sample << Shift;
}


static void AudioCallBack_(void* UserData, int* Output, int Bytes) {
//    int StallMask = 0;
//    int* M = CBStart_(StallMask);
//    require0(M);

	int* M = Mixed;
	int Samples = Bytes / sizeof(*Output);

	#pragma omp simd
	while ( --Samples >= 0 )  {
		*Output++ = Adjust_(*M++);
	}
	
//    CBEnd_();
}


SDL_AudioDeviceID AudioStart(SDL_AudioSpec* SpecOut) {
	SDL_AudioSpec Desired = {
		.freq = 44100,
		.format = AUDIO_S32,
		.channels = 2,
		.samples = AudioBufferCount/2,  // Should be called .frames not .samples
		.callback = (SDL_AudioCallback)AudioCallBack_,
	};

//    Audio.Stream = SDL_OpenAudioDevice(NULL, 0, &Desired, &Audio.Spec, 0);

	auto S = SDL_OpenAudioDevice(NULL, 0, &Desired, SpecOut, 0);
	if (!S) {
		printf( "SDLAudio Error: %s\n", SDL_GetError() );
	}
	return S;
}
