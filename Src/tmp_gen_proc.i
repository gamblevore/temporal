

extern NamedGen TmpGenList[];


NamedGen* NextGenerator(NamedGen* G) {
	if (G) {
		G++;
		if (G->Name)
			return G;
	}
	return 0;
}


static void FindSpikesAndLowest (uSample* Results, int Count, BookHitter& B) {
	u32 Lowest = -1;
	for_ (Count)
		Lowest = std::min(Lowest, (u32)Results[i]);

	u32 MaxTime = (Lowest + 2) * 5;
	
	uSample* Write = Results;
	u32 Spikes = 0;
	for_ (Count) {
		u32 V = *Results++;
		*Write++ = V - Lowest;
		Spikes += (V > MaxTime);
	}

	B.Stats.Spikes += Spikes;
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
	int Space		   = B.GenSpace();
	uSample* OutEnd    = Out + Space;
	uSample* WarmUp    = Out + 2048;
	
	if (OutEnd < WarmUp)
		OutEnd = WarmUp;
	
	B.Stats.SamplesGenerated += (OutEnd - Out);
	(A.Gen->Func)(Out, WarmUp, 0, A.Reps); // warmup
	(A.Gen->Func)(Out, OutEnd, 0, A.Reps);
	FindSpikesAndLowest(Out,  Space,  B);	
	
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
// I wanted to do some kinda mid-point split...
// turns out, it completely failed because the output tends to clump up in ranges.
// (70-75)*1000, (40-45)*1000, etc.

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
	auto Data = B.Out();
	int n = B.Space();
	
	for_(n) {
		u32 s = Data[i];
		H[s & HistoMask]++;

		if (s <= HistoMask) continue;
		Data[i] = s & HistoMax;
	}
}


static void Divide(BookHitter &B) {
	const int List[] = {4, 2, 13, 11, 7, 5, 3};
	for (auto oof : List)
		if (CanDivide(B, oof))
			DoDivide(B, oof);
}


static void PreProcess (BookHitter& B) {
	B.App->Highest = 0;
	B.SampleHisto.assign(HistoMax, 0);
	if (B.App->IsSudo()) return;
	
	RawHisto(B);
	Divide(B);
	GroupHisto(B);
}


static float TemporalGeneration(BookHitter& B, GenApproach& App) {
	auto t_Start = Now();
	B.App = &App;
	B.Stats = {};
	App.Stats = {};

	int Err = pthread_create(&B.GeneratorThread, NULL, &GenerateWrapper, &B);
	if (!Err) Err = pthread_join(B.GeneratorThread, 0);
	if (Err)  B.Stats.Err = Err;

	auto& T = B.Stats;
	float Time = ChronoLength(t_Start);
	App.GenTime = Time;
	T.GenerateTime += Time;
	
	if (T.Err) {
		fprintf( stderr,  "temporal generation err for '%s': %i\n",  App.Gen->Name,  B.Stats.Err);
	} else {
		t_Start = Now();
		App.UseCount++;
		if (!B.IsRetro())
			PreProcess(B);
		float PTime = ChronoLength(t_Start);
		Time += PTime;
		T.ProcessTime += PTime;
	}
	
	return Time;
}
