


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

	for (int bean = 0; bean < 8; bean++) {
		int c = oc;
		if (AsBits) {
			c = !!(c & 0x80);
		} else if (bean) break;
		ccount[c]++;		  /* Update counter for this bin */
		totalc++;
		
		/* Update calculation of serial correlation coefficient */
		double sccun = c;
		if (sccfirst) {
			sccfirst = false;
			scclast = 0;
			sccu0 = sccun;
		} else {
			scct1 = scct1 + scclast * sccun;
		}
		scct2 = scct2 + sccun;
		scct3 = scct3 + (sccun * sccun);
		scclast = sccun;
		oc <<= 1;
	}
}



void RandoStats::Unify(int i, float Low, float High, float Bad, float Value) {
	float Result = (Value - Low) / (High - Low);
	Failed += (Result >= Bad);
	(*this)[i] = Result;
	if (Result > Worst) {
		WorstIndex = i + 1;
		Worst = Result;
	}
}


void RandTest::end(GenApproach& App) {
	/* Calculate serial correlation coefficient */
	scct1 = scct1 + scclast * sccu0;
	scct2 = scct2 * scct2;
	double scc = totalc * scct3 - scct2;
	scc = (!scc) ? (-100000) : ((totalc * scct1 - scct2) / scc);

	/* Scan bins, calculate probability, chi-Square, and arith-mean. */
	int n = (AsBits ? 2 : 256);
	double avg = (AsBits ? 0.5 : 127.5);
	double cexp = totalc / (double)n;  /* Expected count per bin */
	double chisq = 0;
	double datasum = 0;
	
	for_(n) {
		double a = ccount[i] - cexp;
		prob[i] = ((double)ccount[i]) / totalc;	   
		chisq += (a * a) / cexp;
		datasum += ((double)i) * ccount[i];
	}

	double Mean = avg - (datasum / totalc);
	double ent = 0;	/* Calculate entropy */
	for_(n)
		if (prob[i] > 0.0)
			ent += prob[i] * log2(1 / prob[i]);

	double montepi = 4.0 * (((double) inmont) / mcount);

	// My code
	Mean /= 21.0;
	App.Mean += Mean;
	auto& Result = App.Stats;

	Result.Unify(0,		-6.93,	-6.415,		1.8059,		1.0-ent					); // Entropy
	Result.Unify(1, 	217.5,	1810.0,		1.3077,		chisq					); // ChiSq
	Result.Unify(2, 	0.0,	1.0,		1.21,		fabs(Mean)				); // Mean
	Result.Unify(3, 	0,		0.35,		1.428,		fabs(M_PI - montepi)	); // Monte
	Result.Unify(4, 	-1,		-0.953,		4.680,		fabs(0.01 - scc) - 1	); // Serial
	
	App.UseCount++;
}


static void DetectRandomness (BookHitter& P) {
	u8* Start = P.Extracted();
	bool binary = false;  // App.BackToBytes );
	RandTest RT = {};  RT.AsBits = binary;  RT.sccfirst = true;
	RT.GenPatterns();

	for_ (P.App->Stats.Length) {
		u8 C = Start[i];
		RT.PatternCheck(C, i);
		RT.add_byte(C);
	}
	
	RT.end(*P.App);
}

