
extern "C" {

struct GenApproach;
struct Histogram;

bool TmpTimingStartsPoor(void);
Ooof void DrawHistogramSub (GenApproach* App, Histogram& H, float N, string ExtraName);
Ooof string GetCWD();



struct RandoStats;		struct GenApproach;		struct BookHitter;
struct NamedGen; 		struct HTML_Random;
#define uSampleMax			(1ull<<(sizeof(uSample)*8))
typedef std::vector<uSample>				SampleVec;
typedef std::vector<ref(RandoStats)>		StatsVec;
typedef std::vector<ref(GenApproach)>		ApproachVec;
typedef std::vector<ref(ApproachVec)>		CPU_ModeVec;
typedef std::map<string, ref(GenApproach)>	ApproachMap;


#define Time_(R)			TimeInit(); u32 Finish = 0; while (Data < DataEnd) { u32 Start = Time32(); for_(R)
#define TimeEnd 			; Finish = Time32(); *Data++ = TimeDiff(Start,Finish);} TimeFinish();
#define Gen(name) 			u64 name##Generator (uSample* Data, uSample* DataEnd, u32 Input, int Reps)
#define		kSudo	 			1
#define		kChaotic	  		2
#define		GenerationError		-5556

}

