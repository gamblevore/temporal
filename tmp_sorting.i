

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
	
	auto SortComparer = [=] (ref(GenApproach) a, ref(GenApproach) b) {
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
	bh_output Out;

	for_ (N) {
		if (Log) printf( "\n:: Stability %i/%i :: \n", i+1, N );
		for (auto App : Approaches) { 
			if (!NextApproachOK(*App)) return false;
			UseApproach(Out);
		}
		AddToStabilityRank();
	}
	
	SortByBestApproach();
	SaveLists();
	CreateHTMLRandom(LogApproaches, "scoring.html", "Fatum Temporal Randomness Test");
	return true;
}


static void ApproachSort(ApproachVec& V) {
	auto StabilityComparer = [] (ref(GenApproach) a, ref(GenApproach) b) {
		if (a->StableRank < b->StableRank)
			return true;
		if (a->StableRank == b->StableRank)
			return (a->Stats.Worst > b->Stats.Worst);
		return false;
	};
	std::sort(V.begin(), V.end(), StabilityComparer);
}


void BookHitter::SortByBestApproach() {
	ApproachVec Fails;
	LogApproaches = {};
	SudoApproaches = {};
	auto NewMode = New(ApproachVec);

	for (auto R : Approaches)
		if (R->Fails)
			Fails.push_back(R);
		  else if (R->IsSudo())
			SudoApproaches.push_back(R);
		  else
			LogApproaches.push_back(R);

	ApproachSort(LogApproaches);
	ApproachSort(Fails);
	ApproachSort(SudoApproaches);

	for (auto R : LogApproaches)
		NewMode->push_back(R);

	CPU_Modes.insert(CPU_Modes.begin(), NewMode);
	while (CPU_Modes.size() > 16)
		CPU_Modes.pop_back();

	
	for (auto R : Fails)
		LogApproaches.push_back(R);

	for (auto R : SudoApproaches)
		LogApproaches.push_back(R);
		
	App = (*NewMode)[0].get();
	
	string TmpName = App->Name();
	printf("\nSteve chose temporal '%s'\n\n", TmpName.c_str());
}


