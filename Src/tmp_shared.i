

Ooof u64 uint64_hash (u64 x) {
	x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
	x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
	x = x ^ (x >> 31);
	if (!x) return 1;
	return x;
}


Ooof u64 Random64 () {
	static u64 Start = 1;
	Start = uint64_hash(Start);
	return Start;
}


typedef u64 (*GenFunc) (uSample* Data, uSample* DataEnd, u32 Input, int Reps);

struct NamedGen {
	GenFunc		Func;
	cstring	Name;
	u8       	Slowness;
};

