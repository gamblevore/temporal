

static float SpeedScore(float b, float a) {
	float thresh = 1.25;
	if (max(a, b) <= 0) return 0;
	
	float score = fabsf(max(b,a)) / fabsf(min(a,b));
	score = max(score-thresh, 0.0f);
	score = score / 1000.0;
	score = copysign(score, b - a);
	return score; 
}


static void ApproachSort(ApproachVec& V) {
	auto Comparer = [] (ref(GenApproach) a, ref(GenApproach) b) {
		if ((b->Stats.FailedCount) and !(a->Stats.FailedCount))
			return true;
		float Diff = b->Stats.Worst - a->Stats.Worst;
		float Faster = SpeedScore(b->GenTime, a->GenTime);
		Diff += Faster;
		if (Diff > 0)
			return true;
		if (!Diff)
			for_(5)  if ((*b)[i] > (*a)[i])  return true;
		return false;
	};

	std::sort(V.begin(), V.end(), Comparer);
}


static void RemoveSudo(ApproachVec& L) {
	for (int i = (int)L.size()-1; i >= 0; i--)
		if (L[i]->IsSudo())
			L.erase(L.begin() + i);
}


void BookHitter::BestApproachCollector(ApproachVec& L) {
	if (!Conf.DontSort or LogFiles()) {
		if (LogOrDebug()) printf( "\n:: Locating Temporal Randomness in %i locations! :: \n", (int)L.size() );
		
		NamedGen* LastGen = 0;
		for (auto app : L) {
			LastGen = NextApproachOK(*app, LastGen);
			if (!LastGen) return;
			UseApproach(true);
		}
		
		if (!Conf.DontSort)
			ApproachSort(L);
		if (LogFiles())
			CreateHTMLRandom(L,  "scoring.html",  "Batch Test");
	}
	RemoveSudo(L);
}


void BookHitter::ReScore() {
	if (RescoreFreq++ % 4) return;

	DuringTesting = 2;
	auto s = App->Name();
	auto& L = ApproachesForChannel();
	if (LogOrDebug())
		printf("\n:: ReScore %s", s.c_str());

	RequestLimit = 0;
	RescoreSelf = !RescoreSelf;

	auto Orig = App;
	if (!RescoreSelf) {
		u32 i = RescoreIndex++ % L.size();
		App = L[ i ].get();
		SettingApp("rescore");
	}
	float OldWorst = App->Stats.Worst;

	TemporalGeneration(self, *App);
	UseApproach(false);
	ApproachSort(L);

	if (LogOrDebug())
		printf("    %.3f⇝%.3f ::\n", OldWorst, App->Stats.Worst );
	
	DuringTesting = false;
	App = Orig;
	SettingApp("rescore (orig)");
}


static bool ShouldAddApproach(BookHitter& B, GenApproach& oof) {
	// Atomics don't fit except into retro
	if (oof.Reps >= 32 and !B.IsRetro())	return false;
	if (oof.IsAtomic() and !B.IsRetro())	return false;
	if (B.IsChaotic() == oof.IsChaotic())	return true;
	if (oof.IsSudo())						return true; // We remove sudo later anyhow.
	return false;
}


ApproachVec& BookHitter::FindBestApproach(ApproachVec& V) {
	if (V.size())
		return V;
	
	for (auto oof: ApproachList)
		if (ShouldAddApproach(self, *oof))
			V.push_back(oof);

	auto OldApp = App;
	DuringTesting = true;
	BestApproachCollector(V);
	DuringTesting = false;
	App = OldApp;
	SettingApp("find best (orig)");
	
	ResetMinMaxes();
	auto Name = ViewChannel("FindBestApproach")->Name();
	if (LogOrDebug() and !Timing.Err)
		printf(":: Lets use '%s' ::\n", Name.c_str());

	return V;
}


