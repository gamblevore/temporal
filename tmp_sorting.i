

static float SpeedScore(float b, float a) {
	float thresh = 1.25;
	if (std::max(a, b) <= 0) return 0;
	
	float score = fabsf(std::max(b,a)) / fabsf(std::min(a,b));
	score = std::max(score-thresh, 0.0f);
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
	if (LogOrDebug()) printf( "\n:: Locating Temporal Randomness in %li approaches! :: \n", L.size() );
	
	NamedGen* LastGen = 0;
	for (auto App : L) {
		LastGen = NextApproachOK(*App, LastGen);
		if (!LastGen) return;
		UseApproach();
	}
	
	if (!IsRetro())
		ApproachSort(L);
	if (LogOrDebug())
		CreateHTMLRandom(L,  "scoring.html",  "Fatum Temporal Randomness Test");
	RemoveSudo(L);
}


ApproachVec& BookHitter::FindBestApproach(ApproachVec& V) {
	if (V.size())
		return V;

	bool Chaotic = IsChaotic();
	for (auto oof: ApproachList)
		if (!Chaotic or oof->IsChaotic() or oof->IsSudo())
			V.push_back(oof); // we remove sudo later anyhow.

	DuringStability = true;
	BestApproachCollector(V);
	DuringStability = false;
	
	ResetMinMaxes();
	auto Name = ViewChannel()->Name();
	if (LogOrDebug() and !Time.Err)
		printf(":: Temporal choice: '%s'  ::\n", Name.c_str());
	return V;
}


