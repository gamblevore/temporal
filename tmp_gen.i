

//	 										//////// time utilities ////////	 

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
	auto D = B - A;
	if (D < 0) { // wrap around
		D = (B - 0x7fffFFFF) - (A - 0x7fffFFFF);
	}
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


Gen(Sudo) { // just to test our numerical strength.
	static int Oof = 1001;
	int x = Oof;

	while (Data < DataEnd) {
		x ^= x >> 16;
		x *= UINT32_C(0x43021123);
		x ^= x >> 15 ^ x >> 30;
		x *= UINT32_C(0x1d69e2a5);
		x ^= x >> 16;
		*Data++ = x;
	}

	Oof = x;
	return 0;
}


NamedGen GenList[] = {
	{AtomicGenerator,		"atomic"		},
	{BoolGenerator,			"bool"			},
	{FloatSameGenerator,	"float"			},
	{BitOpsGenerator,		"bitops"		},
	{MemoryGenerator,		"memory"		},
	{TimeGenerator,			"time"			},
	{SudoGenerator,			"PSEUDO",	true},
//	{BadGenerator,			"BAD"			},
	{},
};


NamedGen* tr_sudogen() {
	return &GenList[6];
}


NamedGen* tr_nextgen(NamedGen* G) {
	if (!G or !G->Name)
		return &GenList[0];
	G++;
	if (G->Name) return G;
	return 0;
}


static void CollectStats (u32* Results, int Count, BookHitter& S, bool NoMax) {
	S.Time.Measurements += Count;
	u32 Lowest = -1;
	u32 Highest = 0;
	for_ (Count) {
		Lowest = std::min(Lowest, Results[i]);
		Highest = std::max(Highest, Results[i]);
	}

	u32 MaxTime = (NoMax) ? -1 : (Lowest + 2) * 5;
	Highest = std::min(Highest, MaxTime);
	S.Time.Highest = Highest - Lowest;
	
	u32* Write = Results;
	for_ (Count) {
		u32 V = *Results++;
		if (V <= MaxTime)
			*Write++ = V - Lowest;
	}
	
	S.Time.Spikes = Count - (Results - Write);
	S.Time.Measurements -= S.Time.Spikes;
	while (Write < Results)
		*Write++ = -1;
} 


static void* GenerateWrapper (void* arg) {
	BookHitter& P = *((BookHitter*)arg);
	sched_param sch = {sched_get_priority_max(SCHED_FIFO)}; // higher priority = better signals.
	P.Time.Error = pthread_setschedparam(P.GeneratorThread, SCHED_FIFO, &sch);
	puts("1");
	require (!P.Time.Error);

	puts("2");
	GenApproach& A = *P.App;	
	auto Out       = P.Out();
	u32* OutEnd    = Out + P.Space();
	u32* WarmUp    = Out + 2048;
	
	(A.Gen->Func)(Out, WarmUp, 0, A.Reps); // warmup
	(A.Gen->Func)(Out, OutEnd, 0, A.Reps);
	CollectStats(Out,  P.Space(),  P,  A.Gen->Type or !A.AllowSpikes);	
	
	return 0;
}


static bool AllDivisible (BookHitter& P, const int oof) {
	int Divisible = 0;
	auto Data = P.Out();
	int n = P.Time.Measurements;
	for_(n)
		Divisible += ((*Data++) % oof == 0);
	
	int AtLeastThisManyNeeded = n - (n / 128); // 99%
	require (Divisible >= AtLeastThisManyNeeded);
	
	Data = P.Out();
	auto Write = Data;
	for_(n)
		*Write++ = *Data++ / oof;
	return true;
}


static void Divide_Pre (BookHitter& P) {
	for (int oof = 15; oof >= 3; oof -= 2)
		if (AllDivisible(P, oof)) break;
}


static void BitShift_Pre (BookHitter& P) {
	u32 Bits = 0;
	auto Data = P.Out();
	int n = P.Time.Measurements;
	for_(n)
		Bits |= *Data++;
	
	if (!Bits) return;

	int Count = 0;
	while (~Bits & 1<<Count)
		Count++;
	
	if (!Count) return;
	
	Data = P.Out();
	for_(n) {
		auto V = *Data;
		*Data++ = V >> Count;
	}
}


static bool TemporalGeneration(BookHitter& P, GenApproach& App) {
	auto t_Start = std::chrono::high_resolution_clock::now();
	P.App = &App;
	App.Stats = {};
	P.Time = {};
	int Err = pthread_create(&P.GeneratorThread, NULL, &GenerateWrapper, &P);
	if (!Err) Err = pthread_join(P.GeneratorThread, 0);
	if (Err) {
		P.Time.Error = Err;
		printf("temporal generation err for '%s': %i\n", App.Gen->Name, Err);
	} else { 
		P.LastGen = App.Gen;
		P.LastReps = App.Reps;
		BitShift_Pre(P);
		for_(3)
			Divide_Pre(P);
	}
	
	auto t_now = std::chrono::high_resolution_clock::now();
	P.Time.Generation = std::chrono::duration_cast<std::chrono::duration<float>>(t_now - t_Start).count();
	return !Err;
}

