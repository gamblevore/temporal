


float ChiSq(float O, float E) {
	float t = (O - E);
	return (t*t)/E;
}


//  These stats funcs are heavily adapted code, from https://www.fourmilab.ch/random/
static double incirc = pow(pow(256.0, (RandTest::MONTEN / 2)) - 1, 2.0); /* In-circle distance for Monte Carlo computation of PI */
void RandTest::add_byte (int oc) {
	monte[mp++] = oc;	   /* Save character for Monte Carlo */
	if (mp >= MONTEN) {	 /* Calculate every MONTEN character */
		mp = 0;
		mcount++;
		double montex = 0;
		double montey = 0;
		for (int mj = 0; mj < MONTEN / 2; mj++) {
			montex = (montex * 256.0) + monte[mj];
			montey = (montey * 256.0) + monte[(MONTEN / 2) + mj];
		}
		if ((montex * montex + montey *  montey) <= incirc)
			inmont++;
	}

	for(int bean = 0; bean < 8; bean++) {
		int c = oc;
		if (AsBits) {
			c = !!(c & 0x80);
		} else if (bean) break;
		ccount[c]++;		  /* Update counter for this bin */
		totalc++;
		oc <<= 1;
	}
}



void RandoStats::Unify(int i, float Low, float High, float Bad, float Value) {
	float Result = Betweenness(Value, Low, High);
	self[i] = Result;
	if (Result >= Bad) {
		FailedCount++;
		FailedIndexes |= 1 << i;
	}
	if (Result > Worst) {
		WorstIndex = i + 1;
		Worst = Result;
	}
}


void RandTest::end(GenApproach& App) {
	/* Scan bins, calculate probability, chi-Square, and arith-mean. */
	int n = (AsBits ? 2 : 256);				// the name seems backwards?
	double Expected = totalc / (double)n;	/* Expected count per bin */
	double datasum = 0;
	double chisq = 0;
	double ent = 0;	/* Calculate entropy */
	
	for_(n) {
		double Occurred = ccount[i];
		chisq += ChiSq(Occurred, Expected);
		datasum += ((double)i) * Occurred;
		double Prob = Occurred / totalc;	   
		if (Prob > 0.0)
			ent += Prob * log2(1.0 / Prob);
	}

	// My code
	double montepi = 4.0 * (((double) inmont) / mcount);
	double avg = (AsBits ? 0.5 : 127.5);
	double Mean = avg - (datasum / totalc);
	Mean /= 21.0;
	App.Mean += Mean;
	auto& Result = App.Stats;

// No idea if these are "right"?! Tweak them if you wanna improve.
	float EntLengthScale = Result.Length / (32.0*1024.0);
	Result.Unify(0,		0,	    0.5,		0.7,	    (8.0 - ent)*EntLengthScale	); // Entropy
	Result.Unify(1, 	217.5,	1810.0,		0.7,		chisq					); // ChiSq
	Result.Unify(2, 	0.0,	1.0,		1.21,		fabs(Mean)				); // Mean
	Result.Unify(3, 	0,		0.35,		1.428,		fabs(M_PI - montepi)	); // Monte
	Result.Unify(4, 	0,		1,			0.09,		Result.Hist*1.5			); // Histogram

//	Result.Hist = Result.BitsRandomised;
}


static void DetectRandomness_ (GenApproach& App, u8* Start, int n) {
	bool binary = false;
	RandTest RT = {};  RT.AsBits = binary;

	for_ (n)
		RT.add_byte(*Start++);
	
	RT.end(App);
}


float BookHitter::DetectRandomness () {
	DetectRandomness_(*(this->App), Extracted(), App->Stats.Length); 
	return App->Stats.Worst;
}


