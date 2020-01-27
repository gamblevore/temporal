


struct NamedGen {
	GenFunc		Func;
	const char*	Name;
	u8       	Slowness;
	u8       	GenType;
};


struct TimeStats {
	float		Generation;
	float		Processing;
	u32			Highest;
	int			Measurements;
	u16			Spikes;
	u16         Error;
};


struct RandoStats {
	float		Entropy;
	float		ChiSq;
	float		Mean;
	float		Monte;
	float		Serial;
	float       Worst;
	int			Length;
	u8			Failed;
	u8			Type		: 4;
	u8			WorstIndex	: 4;
	
	void Unify(int i, float Low, float High, float Bad, float Value);
	float& operator[] (int i) {
		return (&Entropy)[i];
	}
};


struct GenApproach {
	NamedGen*	Gen;
	RandoStats  Stats;
	float		Mean;
	u16			Fails;
	u16			Reps;
	u16			StableRank;
	u16			UseCount;
	u8			Class;
	u8			Debias			: 1;
	u8			PhysicalSystem	: 1; // non-power of 2 more physical system to creating numbers
	u8			UseMidPoint 	: 1; // just use the midpoint... Find a point where half above and half-below.
	u8			NumForName		: 7;
	u8			AllowSpikes		: 1;
	

	void EndExtract() {
		Fails += Stats.Failed;
	}
	float& operator[] (int i) {
		return (&Stats.Entropy)[i];
	}
	bool IsSudo() {
		return Gen->GenType == kSudo;
	}
	bool IncreaseRank (u32 i) {
		u32 Desired = (u32)StableRank + i;
		StableRank = std::min((int)Desired, (int)0xFFFF);
		return (StableRank != Desired);
	}
	string NameSub() {
		string name = string(Gen->Name) + to_string(Reps);
		if (Debias)				name += "v";
		if (PhysicalSystem)		name += "b";
		if (UseMidPoint)		name += "p";
		if (AllowSpikes)		name += "s";
		return name;
	}
	string Name() {
		if (NumForName) return string("loop_") + to_string(NumForName);
		if (Stats.Type) return MaxNames[Stats.Type];
		return NameSub();
	}
	string FileName(string s="") {
		return "time_imgs/" + Name() + s + ".png";
	}
	static std::shared_ptr<GenApproach> neww() {
		auto M = New(GenApproach);
		*M = {};
		return M;
	}
};
NamedGen* tr_sudogen();


struct RandTest {
	constexpr static const int MONTEN = 6.0;
	constexpr static const double BIGX = 20.0;

	int			ccount[256];			/* Bins to count occurrences of values */
	double		prob[256];				/* Probabilities per bin for entropy */
	int			totalc;					/* Total bytes counted */
	int			AsBits;					/* Treat input as a bitstream */
	int			mp;
	int			intsccfirst;
	int			inmont;
	int			mcount;
	u32			monte[MONTEN];
	double		sccfirst, sccu0, scclast, scct1, scct2, scct3;

//  Funcs
	void		add_byte (int oc);
	void		end(GenApproach& Result);
	
	void 		PatternCheck(u8 C, int i) {}
	void 		GenPatterns() {}
};


struct RandomBuildup {
	u8*				Data;
	GenApproach*    Chan;
	float			Score;
	int				Remaining;
	int				Avail;
	int				Attempt;
	
	float Worst() {
		return std::max(Chan->Stats.Worst, 0.0f);
	}
	
	float RandomnessAdd() {
		float ToAdd = 1.0f - Worst(); 
		return std::max(ToAdd, 0.0f);
	}
};


struct BookHitter {
	GenApproach*	App;
	NamedGen*		LastGen;
	pthread_t		GeneratorThread;
	UintVec			Samples;
	ByteArray		Buff;
	IntVec			RepList;
	ApproachMap		Map;
	ApproachVec		Approaches;
	CPU_ModeVec		CPU_Modes;
	ApproachVec		LogApproaches;
	ApproachVec		SudoApproaches;
	ApproachVec		MinMaxes;
	TimeStats   	Time;
	bool			CreatedDirs;
	u16				LastReps:15;
	u16				Log:1;
	short			UserChannel;

	void DebugRandoBuild(RandomBuildup& B, int N);
	void CreateDirs();
	void CreateHTMLRandomOne(GenApproach& V, string Name);
	void CreateHTMLRandom(ApproachVec& V, string Name, string Title);
	void AddToStabilityRank();
	void FindMinMax();
	void SaveLists();
	bool LoadLists();
	bool LoadListsSub(string Path);
	void CreateVariants();
	int  UseApproach (bh_output& Out);
	bool NextApproachOK(GenApproach& App);
	bool RandomnessBuild (RandomBuildup& B, bh_output& Out);
	bool RandomnessALittle (RandomBuildup& B, bh_output& Out);
	bool StabilityCollector(int N);
	void SortByBestApproach();
	void LogApproach();
	bool LogOrDebug() {
		#ifdef DEBUG
			return true;
		#endif 
		return Log;
	}
	ref(GenApproach) ViewChannel(int Attempt) {
		int i = UserChannel;
		if (i < 0)
			return (SudoApproaches)[(1-i) % SudoApproaches.size()];
		if (!i) i = Attempt;
		return (CurrSorted())[i % CurrSorted().size()];
	}
	ref(GenApproach) operator[] (string Name) {
		return Map[Name];
	}
	ApproachVec& CurrSorted() {
		return (*CPU_Modes[0]);
	}
	void ResetApproach() {
		App = 0;
		LastGen = 0;
		LastReps = 0;
	}
	u32* Out() {
		return &(Samples[0]);
	}
	u8* Extracted() {
		return &(Buff[0]);
	}
	int Space() {
		return (int)Samples.size();
	}
	void AddM (float Default, int Type) {
		auto M = GenApproach::neww();
		for_(5) (*M)[i] = Default;
		M->Stats.Type = Type;
		MinMaxes.push_back(M);
	}
	string CollectInto(ApproachVec& V, int i) {
		auto M = New(GenApproach);
		*M = *App;
		M->NumForName = i;
		V.push_back(M);
		return M->FileName();
	}
	void Allocate(int W) {
		Samples.resize(4 * W * W);
		Buff.resize(Samples.size());
	}
	void CreateReps(int* Reps) {
		RepList = {};
		if (!Reps) {
		#if DEBUG
			RepList = {5, 9, 213};
		#else
			// RepList = {1, 2, 3, 5, 9, 10, 17, 25, 36, 88, 123, 179, 213};
			RepList = {3, 5, 9, 17, 213};
		#endif
		} else {
			while (*Reps) {
				RepList.push_back(*Reps++);
			}
		}
		CreateVariants();
	}
};

