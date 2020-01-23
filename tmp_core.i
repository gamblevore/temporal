

void BookHitter::FindMinMax(GenApproach& S) {
	if (S.Stats.Failed) return;
	int Su = S.IsSudo() * 2;
	auto Min = MinMaxes[0 + Su];
	auto Max = MinMaxes[1 + Su];
	for_(5) {
		(*Max)[i] = std::max(S[i], (*Max)[i]);
		(*Min)[i] = std::min(S[i], (*Min)[i]);
	}
}


int BookHitter::UseApproach (tr_output& Out) {
	auto t_Start = std::chrono::high_resolution_clock::now();
	
	GenApproach& App = *this->App;
	int N = ExtractRandomness(*this);
	App.Stats = {.Length = N};

	if (LogOrDebug()) {
		WriteFile(Extracted(), N, App.Name()+".raw");
		WriteImg(Extracted(), N, App.FileName());
	}
	DetectRandomness( *this );
	FindMinMax(App);
	
	auto t_now = std::chrono::high_resolution_clock::now();
	Time.Generation = std::chrono::duration_cast<std::chrono::duration<float>>(t_now - t_Start).count();

	Out.ProcessTime += Time.Processing;
	Out.GenerateTime += Time.Generation;
	Out.WorstScore = std::max(Out.WorstScore, App.Stats.Worst);

	return N;
}


bool BookHitter::NextApproachOK(GenApproach& App) {
	this->App = &App; 
	if ( App.Gen == LastGen and App.Reps == LastReps )
		return true;
	if ( App.Gen != LastGen )
		printf( "\n:: Method %s :: \n", App.Gen->Name );

	require(TemporalGeneration(*this, App));
	printf( "	:: Reps %i:  \tSpikes=%i\t(Highest=%i) ::\n", App.Reps, Time.Spikes, Time.Highest );
	return true;
}



void BookHitter::CreateVariants() {
	NamedGen* G     = 0;
	auto ModList    = {12, 17, 19, 23}; // arbitrary... can change these to whatever.

	ClassCount      = 0; // reset
	while ((G = tr_nextgen(G)))  for (u16 R : RepList)  {
		for (u8 Mod : ModList) {
			auto App = new GenApproach;
			*App = {.Gen = G,  .Mod = Mod,  .Reps = R,  .Class = ClassCount};
			Approaches.push_back(App); 
		}
		if (ClassCount++ >= 255) {
			debugger; puts("too many classes");
		};
	}

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


bool BookHitter::RandomnessALittle (RandomBuildup& B, tr_output& Out) {
	require (B.Attempt <= 31);
	require (LastGen or StabilityCollector( 1 ));	// (5 - F.Log*3)); 
	B.Chan = ViewChannel(B.Attempt/2);
	require (TemporalGeneration(*this, *B.Chan));		// pthread err
	B.Avail = UseApproach(Out);
	return true;
}


bool BookHitter::RandomnessBuild (RandomBuildup& B, tr_output& Out) {
	// OK so... let's see. We need... a score... of... above 1.
	int N = std::min(B.Avail, B.Remaining);
	u8* Data = XorCopy(Extracted(), B.Data, N);
	float MoreRando = B.RandomnessAdd(); 
	B.Score += MoreRando;
	
	if (MoreRando < 0.5 and !UserChannel) {
		B.Attempt++;
		if (MoreRando < 0.25) { // debug why its failing.
			printf("failed worst = %f\n", B.Chan->Stats.Worst);
			string Bye = App->FileName("_fail");
			WriteImg(Extracted(),  B.Avail,  Bye);
			OpenFile(Bye);
			WriteFile(Extracted(),	N,  App->Name() + ".raw");
			App->Stats = {.Length = B.Avail};
			DetectRandomness( *this );
		}
		return false;
	}

	B.Score = 0;
	B.Remaining -= B.Avail;
	B.Data = Data;
	return true;
}
