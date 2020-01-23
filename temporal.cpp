
//  
//  Generate temporal number stream: © 2019-2020 Theodore H. Smith
//  Could be used in almost anything! Even games :3
//  Can we make a computer FEEL Psychic energy?
//  compile: g++ -pthread -std=c++0x -Os temporal.cpp -o temporal
//	  or use Xcode project
//  

//  TODO:
//  * Ues lasting statistical-mean in the stablity sorter! 
//  * serial-stat too big... sqrt?
//  * siri/chi blockers are too high
//  * Do we even need 256/mod?
//  * put raw files in tmp, the scoring files in chdir
//  * debias using... histograms...
//      * after using multiple approaches!
//  * Keep a list of sorted lists... CPU can only have so many modes.
//     * dont need to re-sort lists... just generate new short ones...
//     * Only keep best rep/gen per list... no mod
//     * Mods can now be flexible! Use the best mod always.
//     * allow list saving?

//  * Seems to generate better results, when "running for a while"...
//    After a while of being stopped for debugging, the results get worse? wierd.
//    

int IgnoredError;
#include "tmp_api.h"
#include "tmp_headers.i"
#include "tmp_typedefs.i"
#include "tmp_defines.i"
#include "tmp_classes.i"
#include "tmp_gen.i"
#include "tmp_stats.i"
#include "tmp_logging.i"
#include "tmp_extraction.i"
#include "tmp_sorting.i"
#include "tmp_core.i"
#include "tmp_api.i"


