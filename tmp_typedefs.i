


typedef unsigned char		u8;
typedef unsigned short		u16;
typedef unsigned int		u32;
typedef unsigned long int	u64;
typedef long int			s64;


struct RandoStats; struct GenApproach; struct BookHitter; struct tr_output; struct NamedGen; 
using   std::ofstream;   using std::string;   using std::to_string;
typedef std::vector<u8>		   		ByteArray;
typedef std::vector<int>			IntVec;
typedef std::vector<u32>			UintVec;
typedef std::vector<RandoStats*>	StatsVec;
typedef std::vector<GenApproach*>	ApproachVec;
typedef std::map<string,RandoStats*>StatsMap;
typedef u64 (*GenFunc) (u32* Data, u32* DataEnd, u32 Input, int Reps);

NamedGen* tr_nextgen(NamedGen* G);
NamedGen* tr_sudogen();

