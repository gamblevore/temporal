

#if DEBUG
	#define StabilityCount 1
#else
	#define StabilityCount 5
#endif


void BookHitter::FindMinMax() {
	GenApproach& S = *App;
	if (S.Stats.FailedCount) return;

	int Su = S.IsSudo() * 2;
	auto Min = MinMaxes[0 + Su];
	auto Max = MinMaxes[1 + Su];
	
	for_(5) {
		(*Max)[i] = std::max(S[i], (*Max)[i]);
		(*Min)[i] = std::min(S[i], (*Min)[i]);
	}
}


float BookHitter::FinalExtractAndDetect (int Mod) {
	ExtractRandomness(*this, 0,   false, true);
	TryLogApproach();
	ExtractRandomness(*this, Mod, true, false);	
	TryLogApproach("p");
	
	return DetectRandomness();
}


static int FinishApproach(BookHitter& B, bh_output* Out, float Time) {
	B.Time.Processing = Time;
	if (Out) {
		auto Ou = *Out;
		Ou.GenerateTime += B.Time.Generation + B.Time.Processing;
		Ou.WorstScore = std::max(Ou.WorstScore, B.App->Stats.Worst);
	}
	return B.App->Stats.Length;
}


int BookHitter::UseApproach (bh_output* Out) {
	auto  t_Start = Now();
	int   BestMod = 0;
	float BestScore = 1000000.0;
	
	for (auto Mod : ModList) {
		ExtractRandomness(*this, Mod);
		float Score = DetectRandomness();
		if (Score < BestScore) {
			BestMod = Mod;
			BestScore = Score;
		}
	}
	
	FinalExtractAndDetect(BestMod);
	App->EndExtract();

	return FinishApproach(*this, Out, ChronoLength(t_Start));
}


bool BookHitter::NextApproachOK(GenApproach& App) {
	this->App = &App; 
	if ( App.Gen == LastGen and App.Reps == LastReps )
		return true;
		
	if ( App.Gen != LastGen )
		printf( "\n:: %s gen :: \n", App.Gen->Name );

	require(TemporalGeneration(*this, App));
	printf( "	:: %03i    \t(took %.3fs) ::\n", App.Reps, Time.Generation );
	return true;
}


string BookHitter::UniqueReps(GenApproach* App, int R, int S) {
	App->Reps = ((R * 10) + S-1) / S; 
	if (App->IsSudo()) App->Reps = 1;

	while (true) {
		string Name = App->Name();
		if (!(*this)[Name]) {
			return Name;
		}
		App->Reps++;
	}
	return "";
}


void BookHitter::CreateApproaches() {
	Approaches = {};
	Map = {};
	MinMaxes = {};

	if (LogOrDebug())
		printf("\n :: Available Generators ::\n\"");

	NamedGen* G = 0;
	while ((G = NextGenerator(G)))  for (auto R : RepList)  {
		auto App = GenApproach::neww();
		App->Gen = G;
		Approaches.push_back(App);
		string Name = UniqueReps(App.get(), R, G->Slowness);
		Map[Name] = App;

		if (LogOrDebug())
			printf("%s ", Name.c_str());
		if (App->IsSudo()) break; // there's really only 1 sudo
	}

	if (LogOrDebug())
		printf("\"\n");

	float Signs[] = {1.0, -1.0};
	for_(4)
		AddM(copysign(100000000, Signs[i%2]), i + 1);

	ResetApproach();
}


static u8* XorCopy(u8* Src, u8* Dest, int N) {
	u8* Write = Dest;
	if (Dest) while (N-- > 0)
		*Write++ = *Src++ ^ *Dest++;
	return Dest;
}


bool BookHitter::CollectPieceOfRandom (RandomBuildup& B, bh_output& Out) {
	require (B.Attempt <= 31);
	require (LastGen or StabilityCollector( StabilityCount )); 
	B.Chan = ViewChannel(B.Attempt/4).get();
	require (TemporalGeneration(*this, *B.Chan));		// pthread err
	B.Avail = UseApproach(&Out);
	return true;
}


void BookHitter::DebugRandoBuild(RandomBuildup& B, int N) {
// it's failing, BUT... often the  output seems good!
// Why? Find out, here!
	printf( "failed worst = %f\n", B.Chan->Stats.Worst );
	string FailPath = App->FileName("_fail");
	WriteImg(Extracted(),  B.Avail,  FailPath);
	FilesToOpenLater.push_back(FailPath);
	string S = App->Name() + ".raw";
	WriteFile(Extracted(),	N,  S);
	App->Stats = {};
	App->Stats.Length = B.Avail;
	DetectRandomness();
}


static int OntopCount;
bool BookHitter::AssembleRandoms (RandomBuildup& B, bh_output& Out) {
	int N = std::min(B.Avail, B.Remaining);
	u8* Data = XorCopy(Extracted(), B.Data, N);
	float MoreRando = B.RandomnessAdded(); 
	B.Score += MoreRando;
	++B.Attempt;

	if (MoreRando >= 0.5 or UserChannel) {
		B.Score = 0;
		B.Remaining -= B.Avail;
		B.Data = Data;
		auto Name = App->Name();
		if (LogOrDebug()) 
			printf( "	:: %s took %.3fs ::\n",  Name.c_str(),  Out.GenerateTime + Out.ProcessTime );
		return true;
	}

	if (LogOrDebug() and MoreRando < 0.25) // debug why its failing.
		DebugRandoBuild(B, N);
	if (LogOrDebug())
		printf("Randomness not good enough, laying more ontop (%i).\n", ++OntopCount);
	return false;
}



void BookHitter::StopStrip() {
	// I can't debug if the compiler strips out these functions!
	if (Samples.size() == 1) { // should never happen
		PrintHisto(*this);
		PrintProbabilities();
		DebugSamples(*this);
	}
}
