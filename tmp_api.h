
extern "C" {
	struct BookHitter;
	 
	struct bh_output {
		void*	Data;
		int		N;
		float	GenerateTime;
		float	ProcessTime;
		float	WorstScore;
	};

	BookHitter*	tr_create	(bool Log);
	void		tr_free		(BookHitter* f);
	void		tr_conf		(BookHitter* f, int Channel, int* Reps);
	int			tr_hitbooks (BookHitter* f, bh_output* Out);
}
