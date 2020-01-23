

bool IncreaseRanks(ApproachVec& Sorted) {
	int i = 0;
	bool MaxRankReached = false;
	for (auto R : Sorted)
		MaxRankReached |= R->IncreaseRank(++i);
	return !MaxRankReached;
}

 
void BookHitter::AddToStabilityRank() {
	ApproachVec Sorted;
	for (auto R : Approaches) {
		R->StableRank++;			// Somehow this makes the temporal-generation output better?
		Sorted.push_back(R);
		R->StableRank--;			// Makes no sense.
	}
	
	auto SortComparer = [=] (GenApproach* a, GenApproach* b) {
		if (a->Stats.Worst < b->Stats.Worst)
			return true;
		if (a->Stats.Worst == b->Stats.Worst)
			for_(5)  if ((*a)[i] < (*b)[i])  return true;
		return false;
	};

	std::sort(Sorted.begin(), Sorted.end(), SortComparer);

	if (IncreaseRanks(Sorted)) return;

	puts("BookHitter: Stability ranks need reset.");
	for (auto R : Sorted) R->StableRank = 0;
	IncreaseRanks(Sorted);
}

bool BookHitter::StabilityCollector(int N) {
	if (!Log) printf( "\n:: Locating Temporal Randomness. Be patient: %li approaches! :: \n", Approaches.size() );
	tr_output Out;

	for_ (N) {
		if (Log) printf( "\n:: Stability %i/%i :: \n", i+1, N );
		for (auto App : Approaches) { 
			if (!NextApproachOK(*App)) return false;
			UseApproach(Out);
		}
		AddToStabilityRank();
	}
	
	SortByBestApproach();
	CreateHTMLRandom(SortedApproaches, "scoring.html");
	return true;
}


static void ApproachSort(ApproachVec& V) {
	auto StabilityComparer = [] (GenApproach* a, GenApproach* b) {
		if (a->StableRank < b->StableRank)
			return true;
		if (a->StableRank == b->StableRank)
			return (a->Stats.Worst > b->Stats.Worst);
		return false;
	};
	std::sort(V.begin(), V.end(), StabilityComparer);
}


void BookHitter::SortByBestApproach() {
	SortedApproaches = {};
	SudoApproaches = {};
	ApproachVec Fails;
	for (auto R : Approaches)
		if (R->Fails)
			Fails.push_back(R);
		  else if (R->IsSudo())
			SudoApproaches.push_back(R);
		  else
			SortedApproaches.push_back(R);

	ApproachSort(SortedApproaches);
	ApproachSort(Fails);
	ApproachSort(SudoApproaches);
// The idea is... we want to get the best of each generator/Rep combination.
// So... first the best atomic-5, then the best memory-7, then the best bitshift-19, etc...
// Makes "fallbacks" more dynamic!

	std::vector<ApproachVec> ClassList(ClassCount);
	for (auto R : SortedApproaches)
		ClassList[R->Class].push_back(R);

	SortedApproaches.resize(0);

	auto PerClass = ClassList[0].size();
	for_(PerClass) {
		ApproachVec CurrBest;
		for (auto& C : ClassList)
			if (i < C.size())
				CurrBest.push_back(C[i]);

		ApproachSort(CurrBest); // OK... so these are all the current best ones. Now... lets sort this too!
		for (auto R : CurrBest)
			SortedApproaches.push_back(R);
	}
	
	for (auto R : Fails)
		SortedApproaches.push_back(R);

	for (auto R : SudoApproaches)
		SortedApproaches.push_back(R);
	
	string TmpName = SortedApproaches[0]->Name();
	printf("Steve chose temporal '%s'\n", TmpName.c_str());
}


