

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
	{AtomicGenerator,		"atomic",	40			}, // rated at 4x slowness
	{BoolGenerator,			"bool",		10			},
	{FloatSameGenerator,	"float",	10			},
	{BitOpsGenerator,		"bitops",	10			},
	{MemoryGenerator,		"memory",	10			},
	{TimeGenerator,			"time",		10			},
//	{CameraGenerator,		"Camera",	10		 	},
	{SudoGenerator,			"Pseudo",	10,		1 	},
	{},
};



NamedGen* NextGenerator(NamedGen* G) {
	if (!G or !G->Name)
		return &GenList[0];
	G++;
	if (G->Name) return G;
	return 0;
}


static void CollectStats (uSample* Results, int Count, BookHitter& S, bool NoMax) {
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
	CollectStats(Out,  B.Space(),  B,  A.IsSudo());	
	
	return 0;
}


static bool AllDivisible (BookHitter& B, const int oof) {
	int Divisible = 0;
	auto Data = B.Out();
	int n = B.Space();
	for_(n)
		Divisible += ((*Data++) % oof == 0);
	
	int AtLeastThisManyNeeded = n - (n / 128); // 99%
	require (Divisible >= AtLeastThisManyNeeded);
	
	Data = B.Out();
	auto Write = Data;
	for_(n)
		*Write++ = *Data++ / oof;
	return true;
}


static void FindHighest (BookHitter& B) {
	auto Data = B.Out();
	int n = B.Space();
	u32 H = 0;
	for_(n)
		H = std::max(*Data++, H);
	if (!H) debugger;
	B.App->Highest = H;
}

static void Divide_Pre (BookHitter& P) {
	for (int oof = 15; oof >= 3; oof -= 2)
		if (AllDivisible(P, oof)) break;
}


static void BitShift_Pre (BookHitter& B) {
	u32 Bits = 0;
	auto Data = B.Out();
	int n = B.Space();
	for_(n)
		Bits |= *Data++;
	
	if (!Bits) return;

	int Count = 0;
	while (~Bits & 1<<Count)
		Count++;
	
	if (!Count) return;
	
	Data = B.Out();
	for_(n) {
		auto V = *Data;
		*Data++ = V >> Count;
	}
}


static bool TemporalGeneration(BookHitter& P, GenApproach& App) {
	auto t_Start = Now();
	P.App = &App;
	P.Time = {};
	App.Stats = {};
	int Err = pthread_create(&P.GeneratorThread, NULL, &GenerateWrapper, &P);
	if (!Err) Err = pthread_join(P.GeneratorThread, 0);
	if (Err)  P.Time.Error = Err;
	if (P.Time.Error) {
		fprintf( stderr, "temporal generation err for '%s': %i\n", App.Gen->Name, P.Time.Error);
	} else {
		App.UseCount++;
		P.LastGen = App.Gen;
		P.LastReps = App.Reps;
		BitShift_Pre(P);
		for_(3)
			Divide_Pre(P);
		FindHighest(P);
	}
	
	P.Time.Generation = ChronoLength(t_Start);
	return !Err;
}


#pragma GCC pop_options
