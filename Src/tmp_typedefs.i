

typedef uint8_t				u8;
typedef uint16_t			u16;
typedef uint32_t			u32;
typedef uint64_t			u64;
typedef int64_t				s64;

typedef u32					uSample;
#define uSampleMax			(1ull<<(sizeof(uSample)*8))


struct RandoStats;		struct GenApproach;		struct BookHitter;
struct NamedGen; 		struct HTML_Random;

using std::string;		using std::to_string;	using std::shared_ptr;
using	std::max;		using std::min;
#define ref(x) std::shared_ptr<x>
typedef std::vector<u8>		   				ByteArray;
typedef std::vector<string>					StringVec;
typedef std::vector<int>					IntVec;
typedef std::vector<uSample>				SampleVec;
typedef std::vector<ref(RandoStats)>		StatsVec;
typedef std::vector<ref(GenApproach)>		ApproachVec;
typedef std::vector<ref(ApproachVec)>		CPU_ModeVec;
typedef std::map<string, ref(GenApproach)>	ApproachMap;

