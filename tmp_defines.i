

// i hate C-style for-loops! XD

#define for_(count)			for (int i = 0; i < count; i++)
#define FOR_(var, count)	for (int var = 0; var < count; var++)
#define require(expr)		if (!(expr)) {return {};}
#define sizecheck(a,b)		if (sizeof(a)!=b) {return -100;} // sizecheck
#define Time_(R)			while (Data < DataEnd) { u32 Start = Time32(); for_(R)
#define TimeEnd ; u32 Finish = Time32(); *Data++ = TimeDiff(Start,Finish);}
#define Gen(name) static u64 name##Generator (uSample* Data, uSample* DataEnd, u32 Input, int Reps)
#define New(x)				std::make_shared<x>()
#define New2(x,a)			std::make_shared<x>(a)
#define New3(x,a,b)			std::make_shared<x>(a,b)
#define New4(x,a,b,c)		std::make_shared<x>(a,b,c)
#define Now()				std::chrono::high_resolution_clock::now()
#define ChronoLength(Start)	(std::chrono::duration_cast<std::chrono::duration<float>>(Now() - Start).count())
#ifdef DEBUG
	#define debugger asm("int3")
#else
	#define debugger
#endif
#define test(cond)	if (!(cond)) {debugger;}


bool				AllowDebiaser	= false; // seems not good enough yet.
int					IgnoredError;
IntVec				ModList			= {12, 13, 17, 19, 23, 31}; // arbitrary... can change these to whatever.
string				ScoreNames[]	= {"entropy", "chisq", "mean", "monte",  "histogram", "persistant"}; 
string				MaxNames[]		= {"",        "min",   "max",  "pmin",   "pmax"}; 
std::vector<string> FilesToOpenLater;

#define kSudo		  	1
#define kSlow		  	2
#define kTotalTemporalGenerateError 0x00F1E
