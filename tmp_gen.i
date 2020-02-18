

//	 										//////// time utilities ////////	 


// give debugging, same timings as normal runs!
#pragma GCC push_options
#pragma GCC optimize ("Os")


static inline u32 rdtscp( u32 & aux ) {
	// remove aux?
	u64 rax, rdx;
	asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
	return (u32)rax;
}


static inline u32 Time32 () {
	u32 T;
	return rdtscp(T);
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


u64 uint64_hash (u64 x) {
	x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
	x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
	x = x ^ (x >> 31);
	if (!x) return 1;
	return x;
}


u64 Random64 () {
	static u64 Start = 1;
	Start = uint64_hash(Start);
	return Start;
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
		u32 Index = TimeFinish >> ((i^x)%32); 
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



NamedGen GenList[] = {
	{FloatSameGenerator,	"float",	10			},
	{SudoGenerator,			"pseudo",	10,	kSudo 	},
	{AtomicGenerator,		"atomic",	40			}, // rated at 4x slowness
	{BoolGenerator,			"bool",		10			},
	{BitOpsGenerator,		"bitops",	10			},
	{MemoryGenerator,		"memory",	10			},
	{TimeGenerator,			"time",		10			},
	{ChaoticGenerator,		"chaotic",	20			},
	{},
};



NamedGen* NextGenerator(NamedGen* G) {
	if (!G or !G->Name)
		return &GenList[0];
	G++;
	if (G->Name) return G;
	return 0;
}


static void FindSpikesAndLowest (uSample* Results, int Count, BookHitter& S, bool NoMax) {
	u32 Lowest = -1;
	for_ (Count)
		Lowest = std::min(Lowest, (u32)Results[i]);

	u32 MaxTime = (NoMax) ? -1 : (Lowest + 2) * 5;
	
	uSample* Write = Results;
	u32 Spikes = 0;
	for_ (Count) {
		u32 V = *Results++;
		*Write++ = V - Lowest;
		Spikes += (V > MaxTime);
	}

	S.Time.Spikes = Spikes;
} 


static void* GenerateWrapper (void* arg) {
	BookHitter& B = *((BookHitter*)arg);
	static int FIFOError = 0;
	static sched_param sch = {};
	if (!FIFOError) {
		auto Priority = sch.sched_priority;
		if (!Priority)
		    sch.sched_priority = sched_get_priority_max(SCHED_FIFO); // higher priority = better signals.
		while (sch.sched_priority >= 0) {
			FIFOError = pthread_setschedparam(B.GeneratorThread, SCHED_FIFO, &sch);
			if (!FIFOError) break;
			sch.sched_priority--;
		};
		if (FIFOError)
			fprintf( stderr, "    :: Temporal Error: Can't set thread priority to FIFO. Error: %i ::\n", FIFOError);
	}
	

	GenApproach& A     = *B.App;	
	auto Out           = B.Out();
	uSample* OutEnd    = Out + B.Space();
	uSample* WarmUp    = Out + 2048;
	
	(A.Gen->Func)(Out, WarmUp, 0, A.Reps); // warmup
	(A.Gen->Func)(Out, OutEnd, 0, A.Reps);
	FindSpikesAndLowest(Out,  B.Space(),  B,  A.IsSudo());	
	
	return 0;
}



const int HistoMax = 1024; 
const int HistoMask = HistoMax - 1; 


Ooof void PrintHisto (BookHitter& B) {
	auto S = B.App->Name();
	printf("Histogram for %s:\n", S.c_str());
	for (auto i:B.SampleHisto)
		printf("%i, ", i);
	printf("0\n");
	// So... what do we do even? We want to split the histogram... in two.
	// or multiple groups. How we split is also interesting.
}


static void GroupHisto (BookHitter& B) {
// I wanted to do some kinda mid-point split here...
// turns out, it completely failed because the output tends to clump up in ranges.
// We get ranges of 40-50, then ranges of 70-90, then ranges of 30-20... etc
// meaning we'd get mostly long strings of white/black. Entirely useless. good idea though.
// Just use the low bits for now...

	int H = 0;
	auto& HList = B.SampleHisto;
	for_(HList.size())
		if (HList[i]) H = i;
	B.App->Highest = H;
}


static bool CanDivide (BookHitter& B, const int oof) {
	int CantDivRemain = (B.Space() / 128);					// 1%
	int n = (int)B.SampleHisto.size();
	for_(n) {
		if (!(i % oof)) continue; // indivisible

		int V = B.SampleHisto[i];
		CantDivRemain -= V;
		if (CantDivRemain <= 0) return 0;
	}
	
	return true;
}


static bool DoDivide (BookHitter& B, const int oof) {
	auto Data = B.Out();
	auto Write = Data;
	int n = B.Space();
	for_(n)
		*Write++ = *Data++ / oof;

// Update histogram
	auto& H = B.SampleHisto;
	int RunningTotal = 0;
	for_(HistoMax) {
		int Low  =     i * oof;
		int High = (i+1) * oof - 1;
		High = std::min(High, HistoMax-1);
		int Total = 0;
		for (int Read = Low; Read <= High; Read++) {
			Total += H[Read];
		}
		RunningTotal += Total;
		H[i] = Total;
	}
	
	if (RunningTotal!=n) debugger; // wat?
	return true;
}


static void RawHisto (BookHitter& B) {

	auto& H = B.SampleHisto;
	auto& C = B.CuriosityHisto;
	auto Data = B.Out();
	int n = B.Space();
	
	for_(n) {
		u32 s = Data[i];
		H[s & HistoMask]++;

		if (s <= HistoMask) continue;
		Data[i] = s & HistoMax;
		s >>= 10;
		C[s & HistoMask]++;
	}
}


static bool Divided(BookHitter &B) {
	const int List[] = {4, 2, 13, 11, 7, 5, 3};
	for (auto oof:List)
		if (CanDivide(B, oof))
			return DoDivide(B, oof);
	return false;
}


static void PreProcess (BookHitter& B) {
	B.App->Highest = 0;
	B.SampleHisto.assign(HistoMax, 0);
	B.CuriosityHisto.assign(HistoMax, 0);
	if (B.App->IsSudo()) return;
	
	RawHisto(B);
	while (Divided(B));
	GroupHisto(B);
}


static bool TemporalGeneration(BookHitter& B, GenApproach& App) {
	auto t_Start = Now();
	B.App = &App;
	B.Time = {};
	App.Stats = {};
	
	int Err = pthread_create(&B.GeneratorThread, NULL, &GenerateWrapper, &B);
	if (!Err) Err = pthread_join(B.GeneratorThread, 0);
	if (Err)  B.Time.Error = Err;
	
	if (B.Time.Error) {
		fprintf( stderr,  "temporal generation err for '%s': %i\n",  App.Gen->Name,  B.Time.Error);
	} else {
		App.UseCount++;
		B.LastGen = App.Gen;
		B.LastReps = App.Reps;
		PreProcess(B);
	}
	
	B.Time.Generation = ChronoLength(t_Start);
	return !Err;
}

#pragma GCC pop_options
