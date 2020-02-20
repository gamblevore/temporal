
extern "C" {

// API

struct BookHitter; struct bh_output;


// You only need these 3 functions
BookHitter*		bh_create			();
bh_output*		bh_hitbooks			(BookHitter* B, unsigned char* Output, int OutLen);
void			bh_free				(BookHitter* B);


#if StevesUsageExample
inline void UsageExample() {
	BookHitter* Stv = bh_create();
	unsigned char Data[1024*1024];
	bh_output Result = bh_hitbooks(Stv, Data, sizeof(Data)); // call as many times as you like...
	printf("Generating %i temporal bytes took %f seconds\n", Result.GenerateTime + Result.ProcessTime );
	bh_free(Stv);  // free once you are finished
}
#endif


// View raw unprocessed temporal stuff... Creates RGB picture!
bh_output*		bh_steve_throwbooks	(BookHitter* B, unsigned char* View, int ViewLen);


// Optional config
void            bh_use_log			(BookHitter* B, bool ActivateLog);
void			bh_use_channel		(BookHitter* B, int Channel);


// Input medium-quality entropy (PEAR GCP project) and get good entropy back. 
unsigned int*	bh_pre_extract		(BookHitter* B,  int N);
int				bh_extract_entropy	(BookHitter* B_, unsigned int* Samples, int N, bh_output* Out);


struct bh_output {
	float	GenerateTime;
	float	ProcessTime;
	float	WorstScore;
	int		Err;
	int		Spikes;
};

}
