


struct NamedGen {
	GenFunc		Func;
	const char*	Name;
	u8       	Slowness;
	u8       	GenType;
};


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


struct GenApproach {
	BookHitter*	Owner;
	NamedGen*	Gen;
	RandoStats  Stats;
	float		Mean;
	u32			Highest;
	u16			Fails;
	u16			Reps;
	u16			UseCount;
	u8			NumForName;
	
	
	static int ShrinkFlags_(GenApproach* App) {
		if (App and App->IsChaotic())
			return kXShrink|kXHisto;
		return kXShrink|kXVonn|kXHisto;
	}
	
	int FinalFlags() {
		return ShrinkFlags_(this);
	}
	
	int DetectFlags() {
		return ShrinkFlags_(this)&~kXHisto;
	}
	
	static int Shrink (GenApproach* App) {
		int Flags = ShrinkFlags_(App);		
		int n = 1;
		if (Flags&kXVonn)   n *= 5;  // 4x on average, but lets say 5 to be safe.
		if (Flags&kXShrink) n *= kXORShrinkAmount;
		return n;
	}

	bool SetGenReps(NamedGen* G, int R) {
		Gen  = G;
		Reps = (R*10 + 9) / G->Slowness;
		return IsSudo();
	}
	void EndExtract() {
		Fails += Stats.FailedCount;
	}
	float& operator[] (int i) {
		return (&Stats.Entropy)[i];
	}
	bool IsSudo() {
		return Gen and (Gen->GenType == kSudo);
	}
	bool IsChaotic() {
		return Gen and (Gen->GenType == kChaotic);
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
		if (App and App->Stats.Type)   return MaxNames[App->Stats.Type];
		if (!App or !App->Gen) return "unknown_";
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
	u8*				Data;
	int				Remaining;
	bool			IsRetro;
	float			AllWorst;
	GenApproach*    Chan;
	int				Loops;
	
	float Worst() {
		return std::max(Chan->Stats.Worst, 0.0f);
	}
	bool KeepGoing() {
		Loops++;
		if (Chan->IsChaotic() or IsRetro)
			return Loops <= 1;
		return Loops <= 3; // be safe... 
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
	ApproachVec		ChaoticApproaches;
	ApproachVec		BasicApproaches;
	ApproachVec		MinMaxes;
	bh_output		Time;
	int				RequestLimit;
	short			UserChannel;
	bool			Log;
	u8				LastReps;
	bool			DuringStability;

// // Funcs
	float			DetectRandomness ();
	void			CreateDirs();
	void			CreateHTMLRandom(ApproachVec& V, string Name, string Title);
	void			DebugProcessFile(string Name);
	void			FindMinMax();
	ref(HTML_Random) HTML(string s, string n);	
	void			CreateApproaches();
	int				UseApproach ();
	NamedGen*		NextApproachOK(GenApproach& App, NamedGen* LastGen);	
	bool			CollectPieceOfRandom (RandomBuildup& B);
	void			BestApproachCollector(ApproachVec& L);
	ApproachVec&	FindBestApproach(ApproachVec& L, bool Chaotic);
	float			FinalExtractAndDetect (int Mod);
	void			TryLogApproach(string name);


	string FileName(string s="") {
		return GenApproach::FileName_(App, s);
	}
	
	bool LogOrDebug() {
		#ifdef DEBUG
			return true;
		#endif 
		return Log;
	}

	bool IsRetro() {
		return UserChannel > 0;
	}

	bool IsChaotic() {
		return UserChannel == 0;
	}
	
	bool ChaosTesting() {
		return IsChaotic() and DuringStability;
	}
	
	bool UsingVon() {
		// fill in later... chaotic might not need both!
		return true;
	}

	bool UsingXOR() {
		return true;
	}

	void OnlyNeedSize(int n) {
		int Shrink = GenApproach::Shrink(App);
		RequestLimit = (256 + Shrink * std::max(n, 0))*8;
	} 

	int UserChannelIndex() {
		int i = UserChannel;
		if (i < 0)
			i = -i;
		if (i) i--;
		return i;
	}
	
	GenApproach* ViewChannel() {
		auto& L = ApproachesForChannel();
		int i = UserChannelIndex() % L.size();
		App = L[i].get();
		return App;
	}
	
	ApproachVec& ApproachesForChannel() {
		if (IsChaotic()) {
			return FindBestApproach(ChaoticApproaches, true);
		} else if (IsRetro()) {
			return ApproachList;
		} else {
			return FindBestApproach(ChaoticApproaches, false);
		}
	}
	
	void ResetMinMaxes() {
		MinMaxes = {};
		float Signs[] = {1.0, -1.0};
		for_(4)
			AddM(copysign(100000000, Signs[i%2]), i + 1);
	}

	void ResetApproach() {
		App = 0;
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
	bool IsFastTimeScoring() {
		return DuringStability and (UserChannel >= 0);
	}
	int Space() {
		int N = (int)Samples.size();
		if (IsFastTimeScoring())
			return N / 16;

		if (RequestLimit > 0 and RequestLimit < N)
			return RequestLimit;
		
		return N;
	}
	void AddM (float Default, int Type) {
		auto M = GenApproach::neww(this);
		for_(5) (*M)[i] = Default;
		M->Stats.Type = Type;
		MinMaxes.push_back(M);
	}
	void Allocate(int N) {
		Samples.resize(N);
		Buff.resize(Samples.size()/8);
		BSL.resize(Samples.size()+1);
	}
	void CreateReps(int* Reps) {
		if (!Reps) {
			RepList = {3, 5, 9, 17, 25, 123};
		#if DEBUG
			RepList = {3, 5, 9, 17, 25};
		#endif
		} else {
			RepList = {};
			while (*Reps)
				RepList.push_back(*Reps++);
		}
		CreateApproaches();
	}
};


void GenApproach::DebugName() {
	if (Owner->LogOrDebug()) {
		string s = Name();
		printf("%s ", s.c_str());
	}
}


string GenApproach::NameSub() {
	string name = string(Gen->Name);
	if (Owner->DuringStability)		name += "_"; // test
	if (!IsSudo())          		name += to_string(Reps);
	if (NumForName)   				name += "_loop" + to_string(NumForName);
	return name;
}

