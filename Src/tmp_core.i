

void BookHitter::FindMinMax() {
	GenApproach& S = *App;
	if (DuringTesting and S.Stats.FailedCount) return;

	if (S.IsSudo()) {
		auto& P = *MinMaxes[2];
		P.UseCount++;
		for_(5) {
			P[i] = max(S[i], P[i]);
		}
	} else {
		auto& Min = *MinMaxes[0];
		auto& Max = *MinMaxes[1];
		
		Min.UseCount++;
		Max.UseCount++;
		
		for_(5) {
			Max[i] = max(S[i], Max[i]);
			Min[i] = min(S[i], Min[i]);
		}
	}
}


float BookHitter::FinalExtractAndDetect (int Mod, bool IsFirst) {
	if (IsRetro()) {
		ExtractRetro(self, IsFirst);
	 } else {
		ExtractRandomness(self, 0, {});
		App->Stats.Length = max(min(App->Stats.Length,2048), App->Stats.Length / 32);             // for style. less is more.
		if (IsFirst)
			TryLogApproach();
		
		auto F = App->FinalFlags();
		if (!IsFirst) F.Log = false;
		
		ExtractRandomness(self, Mod, F);
		if (IsFirst)
			TryLogApproach("p");
	}
	
	return DetectRandomness();
}


static int FinishApproach(BookHitter& B, float Time) {
	auto& App = *B.App;
	App.Fails += App.Stats.FailedCount;
	B.Timing.ProcessTime += Time;
	return App.Stats.Length;
}


int BookHitter::UseApproach (bool IsFirst) {
	auto  t_Start = Now();
	int   BestMod = 0;
	float BestScore = 1000000.0;
	
	if (!IsRetro()) for (auto Mod : ModList) {
		ExtractRandomness(self, Mod, App->DetectFlags());
		float Score = DetectRandomness();
		if (Score < BestScore) {
			BestMod = Mod;
			BestScore = Score;
		}
	}
	
	FinalExtractAndDetect(BestMod, IsFirst);
	FindMinMax();
	return FinishApproach(self, ChronoLength(t_Start));
}


NamedGen* BookHitter::NextApproachOK(GenApproach& app,  NamedGen* LastGen) {
	this->App = &app;
	if ( app.Gen != LastGen  and  LogOrDebug() )
		printf( "\n:: %s gen :: \n", app.Gen->Name );
	LastGen = app.Gen;
	
	float T = TemporalGeneration(self, app);
	require(!Timing.Err);
	if (LogOrDebug())
		printf( "	:: %03i    \t(took %.3fs) ::\n", app.Reps, T );
	return LastGen;
}


static IntVec& RepListFor(BookHitter& B, NamedGen* G) {
	if (matchi(G->Name, "chaotic")) {
		B.ChaoticRepList = {};
		for_(15) B.ChaoticRepList.push_back(i+1);
		return B.ChaoticRepList;
	}
	
	return B.RepList;
}


static void CreateApproachSub(BookHitter& B, NamedGen* G) {
	auto List = RepListFor(B, G);
	for (auto R : List) {
		auto App = GenApproach::neww(&B);
		bool Sudo = App->SetGenReps(G, R);
		B.ApproachList.push_back(App);
		if (Sudo) return;
	}
}


void BookHitter::CreateApproaches() {
	RescoreIndex = 0;
	ApproachList = {};
	BasicApproaches = {};
	RetroApproaches = {};
	ChaoticApproaches = {};

	for (auto G = &TmpGenList[0];  G;  G = NextGenerator(G))
		CreateApproachSub(self, G);

	App = 0;
	ResetMinMaxes();
}


static void XorCopy(u8* Src, u8* Dest, int N) {
	u8* Write = Dest;
	while (N-- > 0)
		*Write++ = *Src++ ^ *Dest++;
}


bool BookHitter::CollectPieceOfRandom (RandomBuildup& B) {
	B.Chan = ViewChannel();
	require(!Timing.Err);
	u32 Least = -1; 
	
	while (B.KeepGoing()) {
		OnlyNeedSize(B.Remaining);
		TemporalGeneration(self, *B.Chan);
		require(!Timing.Err);
		
		int ActualBytes = UseApproach(B.TotalLoops == 1); 
		B.BytesUsed += ActualBytes;
		u32 N = min(ActualBytes, B.Remaining);
		Least = min(Least, N);
		if (IsRetro())
			XorRetro( OoferSpace(),  B.OutgoingData,  N);
		  else
			XorCopy ( Extracted(),   B.OutgoingData,  N);
		B.AllWorst = max(B.AllWorst, B.Worst());
	}
	
	RequestLimit = 0;			// cleanup.
	B.OutgoingData += Least;
	B.Remaining -= Least;
	if (!Least) {
		Timing.Err = GenerationError;
		return false;
	}
	if (B.Remaining > 0) return true;

	return false;
}


Ooof void StopStrip(BookHitter&B) {
	// I can't debug if the compiler strips out these functions!
	if (B.Samples.size() == 1) { // should never happen
		PrintHisto(B);
		PrintProbabilities();
		DebugSamples(B);
	}
}


bh_stats* BookHitter::Hit (u8* Data, int DataLength) {
	if (!Data) return 0; // wat?

	CreateDirs();

	memset(Data, 0, DataLength);
	RandomBuildup B = {Data, DataLength, IsRetro()};
	Timing = {};
	Timing.BytesGiven = DataLength;

	while (CollectPieceOfRandom(B))
		B.Reset();

	if (Conf.AutoReScore)
		ReScore();
	
	Timing.BytesUsed = B.BytesUsed;
	return &Timing;
}


Ooof void ReportStuff (bh_stats* Result) {
	float M = ((float)(Result->SamplesGenerated))/1000000.0;
	float K = ((float)(Result->SamplesGenerated))/1000.0;
	
	if (M >= 0.5)
		printf(":: %.2fMB", M);
	  else
		printf(":: %.2fKB", K);
	printf(" ⇝ %iKB ::\n", (Result->BytesUsed/1024));
}
