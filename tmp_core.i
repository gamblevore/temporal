

void BookHitter::FindMinMax() {
	GenApproach& S = *App;
	if (DuringStability and S.Stats.FailedCount) return;

	int Su = S.IsSudo() * 2;
	auto Min = MinMaxes[0 + Su];
	auto Max = MinMaxes[1 + Su];
	
	for_(5) {
		(*Max)[i] = std::max(S[i], (*Max)[i]);
		(*Min)[i] = std::min(S[i], (*Min)[i]);
	}
}


float BookHitter::FinalExtractAndDetect (int Mod) {
	ExtractRandomness(self, 0, 0);
	App->Stats.Length /= 32;             // for style. less is more.
	TryLogApproach();
	
	int F = App->FinalFlags();
	ExtractRandomness(self, Mod, F);	
	TryLogApproach("p");
	
	return DetectRandomness();
}


static int FinishApproach(BookHitter& B, float Time) {
	auto& App = *B.App;
	App.Fails += App.Stats.FailedCount;
	B.Time.ProcessTime += Time;
	B.Time.WorstScore = std::max(B.Time.WorstScore, App.Stats.Worst);
	return App.Stats.Length;
}


int BookHitter::UseApproach () {
	auto  t_Start = Now();
	int   BestMod = 0;
	float BestScore = 1000000.0;
	
	for (auto Mod : ModList) {
		ExtractRandomness(self, Mod, App->DetectFlags());
		float Score = DetectRandomness();
		if (Score < BestScore) {
			BestMod = Mod;
			BestScore = Score;
		}
	}
	
	FinalExtractAndDetect(BestMod);
	return FinishApproach(self, ChronoLength(t_Start));
}


NamedGen* BookHitter::NextApproachOK(GenApproach& App, NamedGen* LastGen) {
	this->App = &App;
	if ( App.Gen != LastGen )
		printf( "\n:: %s gen :: \n", App.Gen->Name );
	LastGen = App.Gen;
	
	float T = TemporalGeneration(self, App);
	require(!Time.Err);
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
	ApproachList = {};
	BasicApproaches = {};
	ChaoticApproaches = {};

	if (LogOrDebug())
		printf("\n :: Available Generators ::\n\"");

	for (auto G = &GenList[0];  G;  G = NextGenerator(G))
		CreateApproachSub(self, G);

	if (LogOrDebug())
		printf("\"\n");

	ResetApproach();
	ResetMinMaxes();
}


static u8* XorCopy(u8* Src, u8* Dest, int N) {
	u8* Write = Dest;
	if (Dest) while (N-- > 0)
		*Write++ = *Src++ ^ *Dest++;
	return Dest;
}


bool BookHitter::CollectPieceOfRandom (RandomBuildup& B) {
	B.Chan = ViewChannel();
	require(!Time.Err);
	u32 Least = -1; 

	B.Loops = 0;
	while (B.KeepGoing()) {
		TemporalGeneration(self, *B.Chan);
		require(!Time.Err);
	
		u32 N = std::min(UseApproach(), B.Remaining);
		Least = std::min(Least, N);
		XorCopy(Extracted(), B.Data, N);
		B.AllWorst = std::max(B.AllWorst, B.Worst());
	}

	B.Data += Least;
	B.Remaining -= Least;
	return (B.Remaining > 0);
}


Ooof void StopStrip(BookHitter&B) {
	// I can't debug if the compiler strips out these functions!
	if (B.Samples.size() == 1) { // should never happen
		PrintHisto(B);
		PrintProbabilities();
		DebugSamples(B);
	}
}

