

typedef unsigned char		u8;
typedef unsigned short		u16;
typedef unsigned int		u32;
typedef unsigned long int	u64;
typedef long int			s64;

typedef u32					uSample;
#define uSampleMax			(1ull<<(sizeof(uSample)*8))


struct RandoStats;		struct GenApproach;		struct BookHitter;		struct NamedGen; 		struct HTML_Random;
using   std::ofstream;  using std::string;		using std::to_string;	using std::shared_ptr;
#define ref(x) std::shared_ptr<x>
typedef std::vector<u8>		   				ByteArray;
typedef std::vector<int>					IntVec;
typedef std::vector<uSample>				SampleVec;
typedef std::vector<ref(RandoStats)>		StatsVec;
typedef std::vector<ref(GenApproach)>		ApproachVec;
typedef std::vector<ref(ApproachVec)>		CPU_ModeVec;
typedef std::map<string, ref(GenApproach)>	ApproachMap;
typedef u64 (*GenFunc) (uSample* Data, uSample* DataEnd, u32 Input, int Reps);

