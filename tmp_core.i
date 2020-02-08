

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


static float ExtractAndDetect (BookHitter& B, int Mod, bool Debias, bool Log) {
	auto& App = *B.App;
	if (Log or !Debias) {
		ExtractRandomness(B, Mod, false, Log);
		if (Log)
			B.LogApproach();
	}
		
	if (Debias) {
		ExtractRandomness(B, Mod, true, Log);	
		if (Log)
			B.LogApproach("p");
	}
	
	DetectRandomness( B );
	B.FindMinMax();
	return App.Stats.Worst;
}


static int FinishApproach(BookHitter& B, bh_output& Out, float Time) {
	B.Time.Processing = Time;
	Out.GenerateTime += B.Time.Generation + B.Time.Processing;

	Out.WorstScore = std::max(Out.WorstScore, B.App->Stats.Worst);
	return B.App->Stats.Length;
}


int BookHitter::UseApproach (bh_output& Out) {
	auto  t_Start = Now();
	int   BestMod = 0;
	float BestScore = 1000000.0;
	
	for (auto Mod : ModList) {
		float Score = ExtractAndDetect(*this, Mod, false, false);
		if (Score < BestScore) {
			BestMod = Mod;
			BestScore = Score;
		}
	}
	
	ExtractAndDetect(*this, BestMod, false, true); // should be true,true

	App->EndExtract();

	return FinishApproach(*this, Out, ChronoLength(t_Start));
}


void BookHitter::DebugProcessFile(string Name) {
	bh_output Out = {};
	int x=0; int y=0; int comp=0;	
    u8* Result = stbi_load(Name.c_str(), &x, &y, &comp, 1);
    int n = DoBytesToBits(Result, x*y, Extracted());
	stbi_image_free(Result);

	Do_HistogramDebias	(*this, Extracted(), n, Log);
	
	UseApproach(Out);
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


void BookHitter::CreateApproaches() {
	Approaches = {};
	Map = {};
	MinMaxes = {};

	if (LogOrDebug())
		printf("\n :: Available Generators ::\n\"");
	NamedGen* G = 0;
	GenApproach* Prev = 0;
	while ((G = NextGenerator(G)))  for (auto R : RepList)  {
		auto App = GenApproach::neww();
		App->Gen = G;
		App->Reps = ((R * 10) + G->Slowness-1) / G->Slowness; 
		Approaches.push_back(App);
		if (Prev  and Prev->Gen == G  and  Prev->Reps >= App->Reps) {
			App->Reps = Prev->Reps + 1;
		}
		if (LogOrDebug())
			printf("%s ", App->Name().c_str());
		Map[App->Name()] = App;
		Prev = App.get();
		if (App->IsSudo()) // there's really only 1 sudo
			break;
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


bool BookHitter::RandomnessALittle (RandomBuildup& B, bh_output& Out) {
	require (B.Attempt <= 31);
	require (LastGen or StabilityCollector( StabilityCount )); 
	B.Chan = ViewChannel(B.Attempt/4).get();
	require (TemporalGeneration(*this, *B.Chan));		// pthread err
	B.Avail = UseApproach(Out);
	return true;
}


void BookHitter::DebugRandoBuild(RandomBuildup& B, int N) {
// it's failing, BUT... often the  output seems good!
// Why? Find out, here!
	CreateDirs();
	printf( "failed worst = %f\n", B.Chan->Stats.Worst );
	string FailPath = App->FileName("_fail");
	WriteImg(Extracted(),  B.Avail,  FailPath);
	FilesToOpenLater.push_back(FailPath);
	WriteFile(Extracted(),	N,  App->Name() + ".raw");
	App->Stats = {};
	App->Stats.Length = B.Avail;
	DetectRandomness( *this );
}


static int OntopCount;
bool BookHitter::RandomnessBuild (RandomBuildup& B, bh_output& Out) {
	int N = std::min(B.Avail, B.Remaining);
	u8* Data = XorCopy(Extracted(), B.Data, N);
	float MoreRando = B.RandomnessAdd(); 
	B.Score += MoreRando;
	++B.Attempt;

	if (MoreRando >= 0.5 or UserChannel) {
		B.Score = 0;
		B.Remaining -= B.Avail;
		B.Data = Data;
		if (LogOrDebug())
			printf( "	:: %s took %.3fs ::\n",  App->Name().c_str(),  Out.GenerateTime + Out.ProcessTime );
		return true;
	}

	if (LogOrDebug() and MoreRando < 0.25) // debug why its failing.
		DebugRandoBuild(B, N);
	if (LogOrDebug())
		printf("Randomness not good enough, laying more ontop (%i).\n", ++OntopCount);
	return false;
}

