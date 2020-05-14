


struct RandoStats {
	float		Entropy;
	float		ChiSq;
	float		Mean;
	float		Monte;
	float		Hist;
	float       Worst;
	int			Length;
	u32			BitsRandomised;
	u8			FailedCount;
	u8			FailedIndexes;
	u8			Type		: 4;
	u8			WorstIndex	: 4;
	
	void Unify(int i, float Low, float High, float Bad, float Value);
	float& operator[] (int i) {
		return (&Entropy)[i];
	}
};


struct Shrinkers {
	u32 PreXOR	: 6;
	u32 Vonn	: 1;
	u32 Histo	: 1;
	u32 PostXOR	: 6;
	u32 Log		: 1;
};


struct GenApproach {
	BookHitter*	Owner;
	NamedGen*	Gen;
	string		_name_;
	RandoStats  Stats;
	float		Mean;
	float		GenTime;
	u32			Highest;
	u16			Fails;
	u16			Reps;
	u16			UseCount;
	u8			LastMod;
	bool		DisableHTMLGen;
	
	ArchiveFile& Arc(string Extra="");
	ArchiveFile& Png(string Extra="");

	bool IsExternal() {
		return _name_.length();
	}
	bool OhBeQuick();
	static Shrinkers ShrinkFlags_(GenApproach* App) {
		if (App->OhBeQuick()) {
			return {};
		}
		Shrinkers Result = {16, 1, 1};
		if (App and App->IsChaotic())
			Result.PreXOR = 4;
		return Result;
	}
	
	string SimpleName() {
		return string(Gen->Name) + "_" + to_string(Reps);
	}
	
	Shrinkers FinalFlags() {
		auto Result = ShrinkFlags_(this);
		Result.Log = true;
		return Result;
	}
	
	Shrinkers DetectFlags() {
		auto Result = ShrinkFlags_(this);
		Result.Histo = 0;
		return Result;
	}
	
	static int Shrink (GenApproach* App) {
		auto Flags = ShrinkFlags_(App);		
		int n = 1;
		if (Flags.Vonn)		n *= 5;  // 4x on average, but lets say 5 to be safe.
		if (Flags.PreXOR)	n *= Flags.PreXOR;
		if (Flags.PostXOR)	n *= Flags.PostXOR;
		return n;
	}

	bool SetGenReps(NamedGen* G, int R) {
		Gen  = G;
		if (G->Slowness)
			Reps = (R*10 + 9) / G->Slowness;
		  else
			Reps = R;
		return IsSudo();
	}
	
	void EndExtract() {
		Fails += Stats.FailedCount;
	}
	float& operator[] (int i) {
		return (&Stats.Entropy)[i];
	}
	bool IsSudo() {
		return Gen and matchi(Gen->Name, "pseudo");
	}
	bool IsChaotic() {
		return Gen and matchi(Gen->Name, "chaotic");
	}
	bool IsAtomic() {
		return Gen and matchi(Gen->Name, "atomic");
	}
	u64 StablePRndSeed(u64 i = 0) { // Stable-pRnd that changes between runs.
		return (UseCount + 1 + i) * (100 + Reps);
	}
	u32 Cap(u32 Mod) {
		if (IsSudo()) return -1;
		u32 H = Highest;
		return H - (H % Mod);
	}

	void DebugName();
	string NameSub();
	string Name() {
		return Name_(this);
	}
	string FileName(string s="") {
		return FileName_(this, s);
	}
	static string Name_(GenApproach* App) {
		if (!App) return "nil";
		if (App->_name_.length())
			return App->_name_;
		if (App->Stats.Type>3) debugger; 
		if (App->Stats.Type)   return MaxNames[App->Stats.Type];
		if (!App->Gen) return "unknown_";
		return App->NameSub();
	}
	static string FileName_(string Name, string s="") {
		return "time_imgs/" + Name + s + ".png";
	}
	static string FileName_(GenApproach* App, string s="") {
		return FileName_(Name_(App), s);
	}
	static std::shared_ptr<GenApproach> neww(BookHitter* Owner) {
		auto M = New(GenApproach);
		*M = {Owner};
		return M;
	}
};


u64 Seed(GenApproach* A, u64 x) {
	if (!A)
		return (x*10000 + 123)^90128381273176487ull;
	return A->StablePRndSeed(x);
}


struct RandTest {
// improved version of "ent.c", a good project with bad code.
// (what happens when you let scientists write code.)
	constexpr static const int MONTEN = 6.0;
	constexpr static const double BIGX = 20.0;

	int			ccount[256];			/* Bins to count occurrences of values */
	int			totalc;					/* Total bytes counted */
	int			AsBits;					/* Treat input as a bitstream */
	int			mp;
	int			intsccfirst;
	int			inmont;
	int			mcount;
	u32			monte[MONTEN];

//  Funcs
	void		add_byte (int oc);
	void		end(GenApproach& Result);
};


struct RandomBuildup {
	u8*				OutgoingData;
	int				Remaining;
	bool			IsRetro;
	int				TotalLoops;
	int				BytesUsed;
	bool			AnyOK;
	u8				Loops;
	float			AllWorst;
	GenApproach*    Chan;
	
	void Reset() {
		Loops = 0;
		AnyOK = false;
		AllWorst = 0;
	}
	
	float Worst() {
		return max(Chan->Stats.Worst, 0.0f);
	}
	
	bool KeepGoing() {
		Loops++;
		TotalLoops++;
		if (!Chan->Stats.FailedCount)
			AnyOK = true;

		if (Chan->OhBeQuick())
			return Loops <= 1;
		
		int IsChaotic = Chan->IsChaotic(); 
		if (IsRetro or (IsChaotic and AnyOK))
			return Loops <= 1;

		return Loops <= 4;
	}
};


struct BookHitter {
	GenApproach*	App;
	pthread_t		GeneratorThread;
	SampleVec		Samples;
	IntVec			SampleHisto;
	ByteArray		Buff;
	ByteArray		BSL;
	IntVec			RepList;
	IntVec			ChaoticRepList;
	ApproachVec		ApproachList;
	ApproachVec		RetroApproaches;
	ApproachVec		ChaoticApproaches;
	ApproachVec		BasicApproaches;
	ApproachVec		MinMaxes;
	bh_stats		Timing;
	bh_conf			Conf;
	ref(Archive)	Arc;
	string			Unified;
	
	u32				RequestLimit;
	u32				Consumed;
	short			DebugLoopCount;
	u8				RescoreFreq;
	u8				RescoreIndex;
	u8				DuringTesting;
	bool			RescoreSelf;
	bool			CreatedDirs;

// // Funcs
	bh_stats*		Hit (u8* Data, int DataLength);
	void			ReScore();
	void 			SetCrashHandler();
	float			DetectRandomness ();
	void			CreateDirs(string path);
	void			CreateHTMLRandom(ApproachVec& V, string Name, string Title);
	void			DebugProcessFile(string Name);
	void			FindMinMax();
	ref(HTML_Random) HTML(string s, string n);	
	void			CreateApproaches();
	int				UseApproach (bool IsFirst);
	NamedGen*		NextApproachOK(GenApproach& App, NamedGen* LastGen);	
	bool			CollectPieceOfRandom (RandomBuildup& B);
	void			BestApproachCollector(ApproachVec& L);
	ApproachVec&	FindBestApproach(ApproachVec& L);
	float			FinalExtractAndDetect (int Mod, bool IsFirst);
	void			TryLogApproach(string name);


	string FileName(string s = "") {
		return GenApproach::FileName_(App, s);
	}
	
	ref(GenApproach) ExternalGen (string Name, bool HtmlGen) {
		auto R = New(GenApproach);
		R->_name_ = Name;
		R->Owner = this;
		R->UseCount = 1;
		R->DisableHTMLGen = !HtmlGen;
		return R;
	}
	
	void SettingApp(string name) {
	}

	void ExternalReports(string Path) {
		Conf.Log = true;
		Conf.Channel = 0; // if we are marked as "Retro"... reporting doesn't add scores.
		CreateDirs(Path);
	}
	
	void SetChannel(const char* name) {
		bool OK;
		int i = Num(name, OK);
		if (OK) {
			char s = i;
			if (i != s) {
				printf("Can't set channel %i, out of range (-128 to 127)\n", i);
			} else {
				Conf.Channel = s;
				Conf.NamedChannel = "";
			}
		} else {
			Conf.NamedChannel = name;
			Conf.Channel = 1;
		}
	}
	
	bool NoImgs() {
		return (DuringTesting == 2);
	}
	
	
	void SendBack(cstring* argv) {
		if (!Arc->WriteToDisk) {
			Arc->Close();
			Unified = Arc->ConCat.str();
			argv[0] = Unified.c_str();
		}
	}

	bool IsDebug() {
		return DEBUG_AS_NUM;
	}
	bool LogOrDebug() {
		if (Conf.Log == 255) return false;
		return DEBUG_AS_NUM or Conf.Log;
	}
	bool LogFiles() {
		if (Conf.Log == 255) return false;
		return Conf.Log;
	}

	bool IsRetro() {
		return Conf.Channel > 0;
	}

	bool IsChaotic() {
		return Conf.Channel == 0;
	}
	
	bool ChaosTesting() {
		return IsChaotic() and DuringTesting;
	}
	
	void OnlyNeedSize(int N) {
		N = max(N, 0);
		if (IsRetro()) {
			RequestLimit = N;
		} else {
			int Shrink = GenApproach::Shrink(App);
			int SafeExtra = 256;
			int BitsToBytes = 8;
			RequestLimit = (SafeExtra + Shrink * N)*BitsToBytes;
		}
	} 

	GenApproach* ViewChannel(string Reason) {
		auto& L = ApproachesForChannel();
		if (Conf.NamedChannel.length()) {
			App = FindNamedChannel(L, Conf.NamedChannel);
			SettingApp(Reason+": ViewChannel Named: " + Conf.NamedChannel);
		} else {
			int i = Conf.Channel;
			i = (i < 0) ? (-i-1) : (i?i-1:0);
			i = i % L.size();
			App = L[i].get();
			SettingApp(Reason+": ViewChannel num");
		}
		return App;
	}
	
	GenApproach* FindNamedChannel(ApproachVec& L, string s) {
		for (auto a: L) {
			auto N = a->SimpleName();
			if (N == s) {
				return a.get();
			}
		}
		if (!App) {
			string N = L[0]->SimpleName();
			printf("Error: Can't find channel: '%s' (using '%s' instead).\n", s.c_str(), N.c_str());
		}
		return L[0].get();
	}
	
	ApproachVec& ApproachesForChannel() {
		if (IsChaotic())
			return FindBestApproach(ChaoticApproaches);
		  else if (IsRetro())
			return FindBestApproach(RetroApproaches);
		  else
			return FindBestApproach(BasicApproaches);
	}
	
	void ResetMinMaxes() {
		MinMaxes = {};
		AddM( 100000000, 1);
		AddM(-100000000, 2);
		AddM(-100000000, 3);
	}

	uSample* Out() {
		return &(Samples[0]);
	}
	u8* BitSections() {
		return &BSL[0];
	}
	u8* Extracted() {
		return &(Buff[0]);
	}
	u64* OoferExtracted() {
		return (u64*)Extracted();
	}

	int Space() {
		int N = (int)Samples.size();
		
		if (ChaosTesting())
			return N / 16;

		if (DuringTesting)
			return N / 2;

		if (RequestLimit > 0 and RequestLimit < N)
			return RequestLimit;
		
		return N;
	}
	int GenSpace() {
		if (IsRetro()) { // half extra, for temporal cohesion...
			int N = (RetroCount*8)+(RetroCount/2);
			return N;
		}
		return Space();
	}
	void AddM (float Default, int Type) {
		auto M = GenApproach::neww(this);
		for_(5) (*M)[i] = Default;
		M->Stats.Type = Type;
		MinMaxes.push_back(M);
	}
	void Allocate(int N) {
		Arc = New(Archive);
		Samples.resize(N);
		Buff.resize(Samples.size()/8);
		BSL.resize(Samples.size()+1);
	}
	void CreateReps(int* Reps) {
		if (!Reps) {
		#if DEBUG
			RepList = {3, 5, 9,  17,  25, 31};
		#else
			RepList = {3, 5, 9,  17,  25, 31, 63, 85};
		#endif
		} else {
			RepList = {};
			while (*Reps)
				RepList.push_back(*Reps++);
		}
		CreateApproaches();
	}
};


string GenApproach::NameSub() {
	string name = string(Gen->Name);
	if (!IsSudo()) {
		if (Owner->DuringTesting==1)
			name += "_"; // test
		name += to_string(Reps);
	}
	if (!Owner->NoImgs() and Owner->DebugLoopCount) {
		name += "_loop" + to_string(Owner->DebugLoopCount);
	}
	   
	return name;
}

ArchiveFile& GenApproach::Arc(string Extra) {
	Owner->Arc->Open();
	return Owner->Arc->AddFile(Name() + Extra);
}
ArchiveFile& GenApproach::Png(string Extra) {
	Owner->Arc->Open();
	return Owner->Arc->AddFile(FileName(Extra));
}

bool GenApproach::OhBeQuick() {
	return (Owner->Conf.OhBeQuick);
}
