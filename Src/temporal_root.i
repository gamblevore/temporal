

/*  
	Generate temporal number stream: © 2019-2020 Theodore H. Smith
	Could be used in almost anything! Even games :3
	Can we make a computer FEEL Psychic energy?
	We compile the generator separately, because optimisations ruin the output!
*/



// todo:
// * New "bad timer" gens...
	// * How many instructions can we run before the timer ticks.

// * histogram fails for generating big files.
	// * temporal hexdump 1 100mb /dev/null/

// * tweak stuff till the visualiser looks nice!
	// * What can I tweak even?
		// * Need tweak raw ASM!
		// * what about compiling the code in diferent ways and naming it different?
			// * how?
	// * float3 used to give really nice output. Now not. Why? Different compilation sure...
	// but I made all the settings the same :( So its something out of my control!
	// * images look better when compiled from Xcode rather than the terminal. BUT WHY?


//  NEW ALGORITHM:
//  * (An opt. Do for later vers, once people like the existing code.)
//  * histogram debiaser should use sliding window, and be single-pass...
//      * This just gives more data, then dump von-neuman, which costs us 4x data.
//      * Needs to be done in terms of "how long ago did find a section of the same length"?


#include "TemporalLibForProjects.h"

extern "C" {
#include "tmp_funcs.i"
#include "tmp_vars.i"
#include "tmp_shared.i"
#include "tmp_classes.i"
#include "tmp_gen_proc.i"
#include "tmp_density.i"
#include "tmp_stats.i"
#include "tmp_logging.i" 
#include "tmp_histogram.i"
#include "tmp_drawhisto.i"
#include "tmp_debias.i"
#include "tmp_extraction.i"
#include "tmp_sorting.i"
#include "tmp_core.i"
#include "tmp_api.i"
#include "tmp_actions.i"
#include "tmp_runcommand.i"
}

