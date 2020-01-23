
extern "C" {
	struct BookHitter;

	 
	struct tr_output {
		float GenerateTime;
		float ProcessTime;
		float WorstScore;
	};

	BookHitter*	tr_create	(bool Log);
	void		tr_free		(BookHitter* f);
	void		tr_conf		(BookHitter* f, int Channel, int* Reps);
	int			tr_hitbooks (BookHitter* f, void* Data, int Count, tr_output* Out);
}
