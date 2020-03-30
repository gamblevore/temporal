
//  
//  Generate temporal number stream: © 2019-2020 Theodore H. Smith
//  Could be used in almost anything! Even games :3
//  Can we make a computer FEEL Psychic energy?
// 

#include "TemporalLib.h"
#include "tmp_headers.i"
#include "tmp_typedefs.i"
#include "tmp_defines.i"
#include "tmp_shared.i"



extern "C" {

#define ARM_ASM // disable ARM_ASM if its not working on android!
#define TSC_RD			1
#define TSC_mach		2
#define TSC_MRC			3
#define TSC_MRS			4
#define TSC_timespec	5

#if defined(__i386__) || defined(__x86_64__) || defined(__amd64__)
	#define TSC TSC_RD        	// rdtsc
#elif defined(__APPLE__)
	#define TSC TSC_mach		// mach_absolute_time
#elif defined(ARM_ASM) && (__ARM_ARCH >= 6)
	#if ( __WORDSIZE == 32 )
		#define TSC TSC_MRC		// arm32 asm
	#else
		#define TSC TSC_MRS		// arm64 asm
	#endif
#else
	#define TSC TSC_timespec	// clock_gettime
#endif


static inline u32 Time32 () {
#if TSC == TSC_RD
	u64 rax;
	asm volatile ( "rdtscp\n" : "=a" (rax));
	return (u32)rax;
#elif TSC == TSC_mach
	return mach_absolute_time();
#elif TSC == TSC_MRC
	volatile unsigned cc;
	__asm__ __volatile__ ("mrc p15, 0, %0, c9, c13, 0" : "=r"(cc));
	return cc;
#elif TSC == TSC_MRS
	int64_t virtual_timer_value;
	asm volatile("mrs %0, cntvct_el0" : "=r"(virtual_timer_value));
	return virtual_timer_value;
#else
	// GIVES POOR TIMINGS! I DON't KNOW WHY.
	// But... the graphical view looks bad using clock_gettime.
	struct timespec TimeData;
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &TimeData);
	return TimeData.tv_nsec;
#endif
}


static inline void TimeFinish () {
#if (TSC == TSC_MRC)
	__asm__ __volatile__ ("mcr p15, 0, %0, c9, c12, 2" :: "r"(1<<31)); /* stop the cc */
#endif
}

static inline void TimeInit () {
#if (TSC == TSC_MRC)
	__asm__ __volatile__ ("mcr p15, 0, %0, c9, c12, 2" :: "r"(1<<31)); /* stop the cc */
	__asm__ __volatile__ ("mcr p15, 0, %0, c9, c12, 0" :: "r"(5));     /* initialize */
	__asm__ __volatile__ ("mcr p15, 0, %0, c9, c12, 1" :: "r"(1<<31)); /* start the cc */
#endif
}



static int TimeDiff (s64 A, s64 B) {
	s64 D = B - A;
	return (int)D;
}

//	 										//////// Generators ////////	 

Gen(FloatSame) {
	const float x0 = Input + 1;
	const float y0 = Input + 1;
	float x = 0;
	float y = 0;
	Time_ (Reps) {
		x = x0;
		y = y0;
		y = y + 1000.5;
		x = x / 2.0;
		x = fmodf(x,2.0) - (x / 10000000.0);
		x = floor(x)	 - (x * 5000000.0);
		x = fminf(x, MAXFLOAT);
		y = fmaxf(y,-MAXFLOAT);
		x += y;
	} TimeEnd
	
	return x;
}


Gen(Time) {
	u32 x = Input;
	Time_ (Reps) {
		x = x xor Time32();
		x = x xor Time32();
	} TimeEnd

	return x;
}


Gen(Bool) {
	bool f = (Input == 0);
	bool t = (((int)Input) < 1);
	
	Time_ (Reps) {
		f = f and t;
		t = t or f;
		t = f or t;
		f = t and f;
	} TimeEnd
	
	return f;
}


Gen(BitOps) {
	u64 x = Input + 1;
	u64 y = Input + 1;
	Time_ (Reps) {
		y = y + 981723981723;
		x = x xor (x << 63);
		x = x xor (x >> 59);
		x = x xor (x << 5);
		x += y;
	} TimeEnd
	
	return x;
}



std::atomic<u64> ax;
std::atomic<u64> ay;
Gen(Atomic) {
	ax = Input + 1;
	ay = Input + 1;
	Time_ (Reps) {
		ay = ay + 981723981723;
		ax = ax xor (ax << 63);
		ax = ax xor (ax >> 59);
		ax = ax xor (ax << 5);
		ax += ay;
	} TimeEnd
	
	return ax;
}


Gen(Memory) {
	u32 CachedMemory[1024]; // 4KB of data.
	u32 x = Input;
	u32 Place = 0;
	Time_ (Reps) {
		u32 index = Place++ % 1024;
		x = x xor CachedMemory[index];
		CachedMemory[index] = x;
	} TimeEnd
	
	return x;
}




Gen(Chaotic) {
	u32 CachedMemory[1024]; // 4KB of data.
	const float fx0 = Input + 1;
	const float fy0 = Input + 1;
	ax = Input + 1;
	ay = Input + 1;
	float fx = 0;
	float fy = 0;
	u32 f = (Input == 0);
	u64 x = Input + 1;
	u64 y = Input + 1;
	u32 Place = 0;
	u32 index = 0;


	const void* ChaosTable[] = {&&Floats, &&Time, &&Bool, &&Floats2, &&Atomic2, &&BitOps, &&Atomic, &&Memory};

	Time_ (Reps) {
		u32 Index = Finish >> ((i^x)%32); 
		goto* ChaosTable[(Index^i)%8];

Floats:
		fx = fx0;
		fy = fy0;
		fy = fy + 1000.5;
		fx = fx / 2.0;
		x = fx;
		goto Finish;
		
Floats2:
		fx = floor(fx)	 - (fx * 5000000.0);
		fx += fy + 1.0;
		x = fx;
		goto Finish;

Time:
		x = x xor Time32();
		x = x xor Time32();
		goto Finish;

Bool:
		f = (f&1) and (x&1);
		x = (bool)x or (bool)f;
		x = (bool)f or (bool)x;
		f = (bool)x and (bool)f;
		goto Finish;
		
BitOps:
		y = y + 981723981723;
		x = x xor (x << 63);
		x = x xor (x >> 59);
		x = x xor (x << 5);
		x += y;
		goto Finish;

Atomic:
		ay = ay + 981723981723;
		ax = ax xor (ax << 63);
		x = ax;
		goto Finish;

Atomic2:
		ax = ax xor (ax >> 59);
		ax = ax xor (ax << 5);
		ax += ay;
		x = ax;
		goto Finish;
		
Memory:
		index = Place++ % 1024;
		x = x xor CachedMemory[index];
		CachedMemory[index] = (u32)x;
		goto Finish;

Finish:;
	} TimeEnd
	
	return x + (int)fx;
}




Gen(Sudo) { // just to test our numerical strength.
	static u64 Oof = 9709823597812817ULL;
	u64 x = Oof;

	while (Data < DataEnd) {
		x = uint64_hash(x);
		*Data++ = (u32)x;
	}

	Oof = x;
	return 0;
}


NamedGen TmpGenList[] = {
	{	FloatSameGenerator,		"float",	10	},
	{	SudoGenerator,			"pseudo",	10	},
	{	AtomicGenerator,		"atomic",	40	}, // 4x slower
	{	BoolGenerator,			"bool",		10	},
	{	BitOpsGenerator,		"bitops",	10	},
	{	MemoryGenerator,		"memory",	10	},
	{	TimeGenerator,			"time",		10	},
	{	ChaoticGenerator,		"chaotic",	10	},
	{},
};


};
