

void BookHitter::FindMinMax() {
	GenApproach& S = *App;
	if (DuringStability and S.Stats.FailedCount) return;

	int Su = S.IsSudo() * 2;
	auto& Min = *MinMaxes[0 + Su];
	auto& Max = *MinMaxes[1 + Su];
	
	Min.UseCount++;
	Max.UseCount++;
	
	for_(5) {
		Max[i] = std::max(S[i], Max[i]);
		Min[i] = std::min(S[i], Min[i]);
	}
}


float BookHitter::FinalExtractAndDetect (int Mod) {
	if (IsRetro()) {
		ExtractRetro(self);
	 } else {
		ExtractRandomness(self, 0, {});
		App->Stats.Length /= 32;             // for style. less is more.
		TryLogApproach();
		
		ExtractRandomness(self, Mod, App->FinalFlags());
		TryLogApproach("p");
	}
	
	return DetectRandomness();
}


static int FinishApproach(BookHitter& B, float Time) {
	auto& App = *B.App;
	App.Fails += App.Stats.FailedCount;
	B.Stats.ProcessTime += Time;
	B.Stats.WorstScore = std::max(B.Stats.WorstScore, App.Stats.Worst);
	return App.Stats.Length;
}


int BookHitter::UseApproach () {
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
	
	FinalExtractAndDetect(BestMod);
	FindMinMax();
	return FinishApproach(self, ChronoLength(t_Start));
}


NamedGen* BookHitter::NextApproachOK(GenApproach& App, NamedGen* LastGen) {
	this->App = &App;
	if ( App.Gen != LastGen and LogOrDebug() )
		printf( "\n:: %s gen :: \n", App.Gen->Name );
	LastGen = App.Gen;
	
	float T = TemporalGeneration(self, App);
	require(!Stats.Err);
	if (LogOrDebug())
		printf( "	:: %03i    \t(took %.3fs) ::\n", App.Reps, T );
	return LastGen;
}


static IntVec& RepListFor(BookHitter& B, NamedGen* G) {
	if (G->GenType == kChaotic) {
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
		App->DebugName();
		if (Sudo) return;
	}
}


void BookHitter::CreateApproaches() {
	RescoreIndex = 0;
	ApproachList = {};
	BasicApproaches = {};
	RetroApproaches = {};
	ChaoticApproaches = {};

	if (LogOrDebug())
		printf("\n :: Available Generators ::\n\"");

	for (auto G = &TmpGenList[0];  G;  G = NextGenerator(G))
		CreateApproachSub(self, G);

	if (LogOrDebug())
		printf("\"\n");

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
	require(!Stats.Err);
	u32 Least = -1; 

	while (B.KeepGoing()) {
		OnlyNeedSize(B.Remaining);
		TemporalGeneration(self, *B.Chan);
		require(!Stats.Err);
	
		u32 N = std::min(UseApproach(), B.Remaining);
		Least = std::min(Least, N);
		if (IsRetro())
			XorRetro(Extracted(),  B.Data,  N);
		  else
			XorCopy (Extracted(),  B.Data,  N);
		B.AllWorst = std::max(B.AllWorst, B.Worst());
	}

	RequestLimit = 0; // cleanup.
	B.Data += Least;
	Stats.BytesOut += Least;
	B.Remaining -= Least;
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

