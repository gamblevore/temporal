
//  
//  Generate temporal number stream: © 2019-2020 Theodore H. Smith
//  Could be used in almost anything! Even games :3
//  Can we make a computer FEEL Psychic energy?
//  compile: g++ -pthread -std=c++0x -Os steve_lib.cpp -o steve_breathe
//	  or use Xcode project
//  


//  TODO:
//  * try to get a stable API out! With retro...
// 		* Retro can get say 4x64... try extract the randomness
//		* Do this 144x. So 4.5K. 
//			* Just use as seeds...
//  * Perfect bit debias should use histo! not bitcounts...
//  * The "need more" thing can be via rnd-detection on the output data!
//       * Nice! Don't need to worry about score... anymore.

// Actual use:
//		* Generators have bad scores. Why?
//		* should save MOD... considering that for short randomdata... the detectors can't detect very well... And just give bad result.


//  * xor could lower on chaotic, but keep VN?
//  * Reset score every so often... like 16 attempts or whatever.
//  	* Just test for 0.5 seconds max, every 5 seconds or so...
// 		* Then re-sort.



//  NEW ALGORITHM: (more of an opt, do for a later version once people are happy with existing code.)
//  * histogram debiaser should use sliding window, and be single-pass...
//      * This just gives more data, then dump von-neuman, which costs us 4x data.
//		* maybe via a "one byte per bit-length" system.
//			* Easy to delete bit-sections! Just delete 1 byte.
//      * Maybe each bit-section-length should store the "position of how long ago did
//        we find section N of the same length"?
//        For example, if bit-section-length=4, then we might expect no closer than 60 bytes
//        So we can add/remove things in a variable window-length per bit-section-length?


#include "SteveLib.h"
#include "tmp_headers.i"
#include "tmp_typedefs.i"
#include "tmp_defines.i"
#include "tmp_math.i"
#include "tmp_classes.i"
#include "tmp_gen.i"
#include "tmp_stats.i"
#include "tmp_img.i"
#include "tmp_logging.i"
#include "tmp_saving.i"
#include "tmp_histogram.i"
#include "tmp_drawhisto.i"
#include "tmp_debias.i"
#include "tmp_extraction.i"
#include "tmp_sorting.i"
#include "tmp_core.i"
extern "C" { // A simple C API!
	#include "tmp_api.i"
}
#include "tmp_demo.i"



