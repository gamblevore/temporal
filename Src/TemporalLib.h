
// API

extern "C" {

struct BookHitter; struct bh_stats; struct bh_conf;

// You only need these 3 funcs
BookHitter*		bh_create			();
bh_stats*		bh_hitbooks			(BookHitter* B,  unsigned char* Output,  int OutLen);
void			bh_free				(BookHitter* B);


// visualisation
int				bh_view_colorisedsamples(BookHitter* B, unsigned char* Out, int OutLength);
int				bh_view_rawsamples		(BookHitter* B, unsigned char* Out, int OutLength);


// config
bh_conf*		bh_config			(BookHitter* B);


// Tells the bookhitter to write the html debug-log-files to disk.
void			bh_logfiles			(BookHitter* B);


#ifdef LibUsageExample
inline void UsageExample() {
	BookHitter* Stv = bh_create();
	unsigned char Data[1024*1024];
	auto T = bh_hitbooks(Stv, Data, sizeof(Data)); // call as many times as you like...
	printf("%i temporal bytes in %fs\n", T->GenerateTime + T->ProcessTime );
	bh_free(Stv);  // free once you are finished
}
#endif


// Input medium-quality entropy (PEAR GCP project) and get good entropy back. 
unsigned int*	bh_extract_input	(BookHitter* B,  int N);
int				bh_extract_perform	(BookHitter* B_, unsigned int* Samples, int N, bh_stats* Out);


struct bh_stats {
// stats, can be ignored
	float	GenerateTime;
	float	ProcessTime;
	float	WorstScore;
	int		Spikes;
	int		SamplesGenerated;
	int		BytesOut; // BytesOut is equal to amount requested in bh_hitbooks.

// Error number incase of error.
	int		Err;
};


struct bh_conf {
	unsigned char  	Channel;
	unsigned char   Log;
	unsigned char   DontSortRetro;
	unsigned char   AutoRetest;
};

}
