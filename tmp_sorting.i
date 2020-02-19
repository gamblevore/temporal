


static void ApproachSort(ApproachVec& V) {
	auto Comparer = [] (ref(GenApproach) a, ref(GenApproach) b) {
		if ((b->Stats.FailedCount) and !(a->Stats.FailedCount))
			return true;
		if (b->Stats.Worst > a->Stats.Worst)
			return true;
		if (b->Stats.Worst == a->Stats.Worst)
			for_(5)  if ((*b)[i] > (*a)[i])  return true;
		return false;
	};

	std::sort(V.begin(), V.end(), Comparer);
}


void BookHitter::BestApproachCollector(ApproachVec& L) {
	if (!Log) printf( "\n:: Locating Temporal Randomness in %li approaches! :: \n", L.size() );
	
	for (auto App : L) {
		if (!NextApproachOK(*App)) return;
		UseApproach();
	}
	
	ApproachSort(L);
	CreateHTMLRandom(L, "scoring.html", "Fatum Temporal Randomness Test");

	for (int i = (int)L.size()-1; i >= 0; i--)
		if (L[i]->IsSudo())
			L.erase(L.begin() + i);
}


ApproachVec& BookHitter::FindBestApproach(ApproachVec& V, bool Chaotic) {
	if (V.size())
		return V;

	for (auto oof: ApproachList)
		if (!Chaotic or oof->IsChaotic() or oof->IsSudo())
			V.push_back(oof); // we remove sudo later anyhow.

	DuringStability = true;
	BestApproachCollector(V);
	DuringStability = false;
	
	auto Name = V[0]->Name();
	if (LogOrDebug() and !Time.Err)
		printf("    :: Steve chose '%s' ::\n", Name.c_str());
	return V;
}


