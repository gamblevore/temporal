
extern "C" {
	struct BookHitter;
	 
	struct bh_output {
		void*	Data;
		int		DataLength;
		float	GenerateTime;
		float	ProcessTime;
		float	WorstScore;
	};

	BookHitter*	bh_create	(bool Log);
	void		bh_free		(BookHitter* f);
	void		bh_conf		(BookHitter* f, int Channel, int* Reps);
	int			bh_hitbooks (BookHitter* f, bh_output* Out);
}
