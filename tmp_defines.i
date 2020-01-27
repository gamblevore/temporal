

// i hate C-style for-loops! XD

#define for_(count)			for (int i = 0; i < count; i++)
#define FOR_(var, count)	for (int var = 0; var < count; var++)
#define require(expr)		if (!(expr)) {return {};}
#define gexpect(cond, err)	if (!(cond)) {return err;}
#define sizecheck(a,b)		if (sizeof(a)!=b) {return -100;} // sizecheck
#define Time_(R)			while (Data < DataEnd) { u32 Start = Time32(); for_(R)
#define TimeEnd ; u32 Finish = Time32(); *Data++ = TimeDiff(Start,Finish);}
#define Gen(name) static u64 name##Generator (u32* Data, u32* DataEnd, u32 Input, int Reps)
#define New(x) std::make_shared<x>()
#ifdef DEBUG
	#define debugger asm("int3")
#else
	#define debugger
#endif


int		IgnoredError;
IntVec	ModList			= {12, 13, 17, 19, 23, 31}; // arbitrary... can change these to whatever.
string  ScoreNames[]	= {"entropy", "chisq", "mean", "monte",  "serial", "persistant"}; 
string  MaxNames[]		= {"",        "min",   "max",  "pmin",   "pmax"}; 
#define kSudo		  	1
#define kSlow		  	2
#define kTotalTemporalGenerateError 0x00F1E
