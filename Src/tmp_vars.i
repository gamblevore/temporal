

bool				AllowDebiaser	= false; // seems not good enough. but i have a better idea.
const int			RetroCount		= 144 * 16;
const IntVec		ModList			= {0, 2, 12, 13, 17, 19, 23, 31}; // arbitrary... can change these to whatever.
const string		ScoreNames[]	= {"entropy", "chisq", "mean", "monte",  "histogram", "persistant"}; 
const string		MaxNames[]		= {"",        "min",   "max",  "pseudo"}; 
int					Environment		= 0;
StringVec 			FilesToOpenLater;


typedef u64 (*GenFunc) (uSample* Data, uSample* DataEnd, u32 Input, int Reps);
