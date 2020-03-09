

/*  
	Generate temporal number stream: © 2019-2020 Theodore H. Smith
	Could be used in almost anything! Even games :3
	Can we make a computer FEEL Psychic energy?
	We compile the generator separately, because optimisations ruin the output!
*/


// todo:
// * "temporal score -1" gives bad result for html...
// * chaotic gen seems slower than should be?
// * tweak stuff till the visualiser looks nice!
	// float3 used to give really nice output. Now not. Why? Different compilation sure...
	// but I made all the settings the same :( So its something out of my control!


//  NEW ALGORITHM:
//  * (An opt. Do for later vers, once people like the existing code.)
//  * histogram debiaser should use sliding window, and be single-pass...
//      * This just gives more data, then dump von-neuman, which costs us 4x data.
//      * Needs to be done in terms of "how long ago did find a section of the same length"?


#include "TemporalLib.h"
#include "tmp_headers.i"
#include "tmp_stb.i"
extern "C" {
#include "tmp_typedefs.i"
#include "tmp_defines.i"
#include "tmp_vars.i"
#include "tmp_opt.i"
#include "tmp_shared.i"
#include "tmp_math.i"
#include "tmp_classes.i"
#include "tmp_gen_proc.i"
#include "tmp_stats.i"
#include "tmp_img.i"
#include "tmp_logging.i"
#include "tmp_histogram.i"
#include "tmp_drawhisto.i"
#include "tmp_debias.i"
#include "tmp_extraction.i"
#include "tmp_sorting.i"
#include "tmp_core.i"
#include "tmp_api.i"
}



