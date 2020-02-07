

int Log2i(u32 i) {
	return 32-__builtin_clz(i);
}


float Betweenness(float x, float Low, float High) {
	return (x - Low) / (High - Low);
}


float Interp(float x, float LowVal, float HighVal) {
	return LowVal + x * (HighVal - LowVal); 
}


u64 FracShift(int s, int sh) {
	if (sh < 0) debugger;
	if (s < 0)  return 0;
	return ((((u64)s) * 0x80000000u) >> sh);
}


u64 PosShift(int s, int sh) {
	if (s < 0) return 0;
	u64 i = s;
	return (sh >= 0) ? (i << sh) : 0;
}


u64 HistoCount(int N, int X) {
	int n = 1 + N - X;
	return PosShift(1ul, n-1ul) + PosShift(n-2ul, n-3ul);
}


float HistoProb(int N, int X) {
	// An ass-ton of logic hidden here.
	// We avoid directly calculating:
	//      ((1<<(n-1)) + ((n-2)<<(n-3)))   /  (1<<n)
	// because n is around 65536. (1<<n) lol.
	// This equality: (1<<a)/(1<<b) == (1<<(a-b))
	// brings (a-b) into reasonable range, and removes a divide!
	// because (a-b) is always negative for us,
	// we right-shift instead, using fixed-point

	if (X > N  or  N <= 0  or  X <= 0) return 0;
	
	u64 CountA = FracShift(1, X);
	u64 CountB = FracShift(N - X - 1, X + 2);
	double P2 = (CountA + CountB);

	P2 /= (double)(0x80000000u);
	return P2;
}

