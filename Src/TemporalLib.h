
// API

#include <stdint.h>

extern "C" {

struct BookHitter; struct bh_stats; struct bh_conf;

// You only need these 3 funcs
BookHitter*		bh_create			();
bh_stats*		bh_hitbooks2		(BookHitter* B,  unsigned char* Output,  int OutLen,  bool Hex);
void			bh_free				(BookHitter* B);

// debugging
int				bh_run_command		(BookHitter* B, const char** argv, bool WriteToString);
void			bh_extract_archive	(const char* Data, const char* Path);
// rnd
uint64_t		bh_rand_u64			(BookHitter* B);
double			bh_rand_double		(BookHitter* B);
uint32_t		bh_rand_u32			(BookHitter* B);
float			bh_rand_float		(BookHitter* B);

// visualisation
int				bh_colorise_external		(unsigned char* Input, int InLength, unsigned char* WriteTo);
int				bh_view_colorised_samples	(BookHitter* B, unsigned char* Out, int OutLength);
int				bh_view_rawsamples			(BookHitter* B, unsigned char* Out, int OutLength);


// config
bh_conf*		bh_config			(BookHitter* B);


// Tells the bookhitter to write the html debug-log-files to disk.
void			bh_logfiles			(BookHitter* B);

// outdated
bh_stats*		bh_hitbooks			(BookHitter* B,  unsigned char* Output,  int OutLen);


// Input medium-quality entropy (PEAR GCP project) and get good entropy back. 
unsigned int*	bh_extract_input	(BookHitter* B,  int N);
int				bh_extract_perform	(BookHitter* B_, unsigned int* Samples, int N, bh_stats* Out);


struct bh_stats {
// stats, can be ignored
	float	GenerateTime;
	float	ProcessTime;
	int		Spikes;
	int		SamplesGenerated;
	int		BytesUsed;  // not bytes output, but throughput... including wasted bytes.
	int		BytesGiven; // not bytes output, but throughput... including wasted bytes.
	const char* ApproachName;
	int 	ApproachReps;
	
// Error number. 0 means no error.
	int		Err;
};


struct bh_conf {
	         char  	Channel;
	unsigned char   Log;
	unsigned char   DontSortRetro;
	unsigned char   AutoReScore;
};

}
