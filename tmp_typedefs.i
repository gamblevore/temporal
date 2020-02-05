

typedef unsigned char		u8;
typedef unsigned short		u16;
typedef unsigned int		u32;
typedef unsigned long int	u64;
typedef long int			s64;


struct RandoStats; struct GenApproach; struct BookHitter; struct NamedGen; 
using   std::ofstream;   using std::string;   using std::to_string;   using std::shared_ptr;
#define ref(x) std::shared_ptr<x>
typedef std::vector<u8>		   				ByteArray;
typedef std::vector<int>					IntVec;
typedef std::vector<u32>					UintVec;
typedef std::vector<ref(RandoStats)>		StatsVec;
typedef std::vector<ref(GenApproach)>		ApproachVec;
typedef std::vector<ref(ApproachVec)>		CPU_ModeVec;
typedef std::map<string, ref(GenApproach)>	ApproachMap;
typedef u64 (*GenFunc) (u32* Data, u32* DataEnd, u32 Input, int Reps);

