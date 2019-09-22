
//
//  Copyright © 2019 Theodore H. Smith
//  Generate temporal number stream.
//  For the fatum project
//  Just fooling around for now!
//  But if useful could be used in almost anything!
//  Even games :3


//  compile: gcc -std=c++0x -lc++ -Os temporal_main.cpp -o temporal
//      or use the Xcode project supplied


#include <iostream>
#include <sys/stat.h>
#include <vector>

#define __TEMPORAL_RESEARCH_IMPLEMENTATION__
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBIW_WINDOWS_UTF8
#include "temporal_research.h"
#include "stb_image_write.h"



struct ScoreAndName {
    double      Score;
    std::string Name;
    bool operator<(const ScoreAndName &rhs) const { return Score < rhs.Score; }
};
typedef std::vector<unsigned char>  ByteArray;
std::vector<ScoreAndName> BestRandoms;



static const char* SubFolderName = "time_imgs";
void PostProcess (TemporalGeneratorParams& P, ByteArray& Bytes, int Mod) {
    auto Data = P.Out;
    
    for_(Bytes.size()) {
        auto V = *Data++;
        if (Mod) {
            V = (V % Mod) * (256/Mod);
        }
        if (V >= 256) {V = 255;}
        Bytes[i] = V;
    }
}


std::string Outputfile (TemporalGeneratorParams& P, ByteArray& Bytes, int W, int Mod) {
    std::string name = "";
    name += P.Stats->Name;
    name += std::to_string(P.RepetitionsPerSample);
    if (Mod) {
        name += "(";
        name += std::to_string(Mod); 
        name += ")";
    }
    name += ".png";
    stbi_write_png_compression_level = 9;

    std::string Path = SubFolderName;
    Path += "/";
    Path += name;
    stbi_write_png(Path.c_str(), W, W, 1, &Bytes[0], W);
    return name;
}



double RandomBadness(std::vector<int>& Arr, double Total, double Size) {
    // so... we have some totals. find some kinda deviation?
    // first get the average, then find the diff between averages?
    double Av = Total / (double)Arr.size();
    double Offness = 0.0;
    for (auto i: Arr) {
        Offness += fabs(Av - (double)i);
    }
    return Offness * pow(Size, 0.1);
}


double DetectRandomness (ByteArray& Bytes, int Mod) {
    int n = (int)Bytes.size();
    double Worst = 0;
    int WorstIndex = 0;
    
    for (int Chunk = 16; Chunk < 64; Chunk++) {
        std::vector<int> Arr;
        double TotalTotal = 0;
        for (int i = 0; i < n; i += Chunk) {
            int Total = 0;
            for (int j = 0; j < Chunk; j++) {
                Total += Bytes[j+i];            
            }
            TotalTotal += (double)Total;
            Arr.push_back(Total);
        }
        
        double Bad = RandomBadness(Arr, TotalTotal, ((double)Chunk)/10.0);
        if (Bad > Worst) {
            Worst = Bad;
            WorstIndex = Chunk;
        }
    }
    
    return Worst/10000.0;
}



void TryOutputFile (TemporalGeneratorParams& P, ByteArray& Bytes, int W, int Mod) {
    // detect randomness... first
    PostProcess(P, Bytes, Mod);
    double Score = DetectRandomness(Bytes, Mod);
    printf("    :: Patternyness: %f ::\n", Score);

    auto name = Outputfile(P, Bytes, W, Mod);
    
    BestRandoms.push_back({Score, name});
}



int main (int argc, const char * argv[]) {
    puts(
R"(Research into temporal-random-number generation.

Generates png files in your current directory, for you to check if the randomness "seems good" or not.

The idea is to use the randomness in "how long" an instruction takes, as a source of physically based randomness.

No idea if this randomness is "good" or not, yet. It has promise, but there are a lot of questions to answer!
)");

    int StupidUnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
    mkdir(SubFolderName, StupidUnixMode);

    const int W = 256;
    const int N = W*W;
    ByteArray Bytes (N);

    for_(TemporalGeneratorTypeCount) {
        unsigned int Method = i;
        const char* Name = tr_generator_name(i);
        printf("\n:: Method %s :: \n", Name);
        unsigned int TemporalStream[N];

        int RepVariations[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 25, 36, 50, 88, 123, 179, 213};
        FOR_(R, CArrayLength(RepVariations)) {
            int Reps = RepVariations[R];
            TemporalGeneratorStats S = {};
            TemporalGeneratorParams P = { TemporalStream, N, Reps, Method, &S };
            
            if (!tr_generate(P)) {
                printf("temporal err with '%s': %i\n", Name, S.Error);
                return S.Error;
            }

            TryOutputFile(P, Bytes, W, 17);
            TryOutputFile(P, Bytes, W, 16);
            printf("    :: Reps %i: Spikes=%i (Highest=%i) ::\n", Reps, S.Spikes, S.Highest );
        }
        printf(":: Ending %s :: \n\n", Name);
    }
    
    std::sort(BestRandoms.begin(), BestRandoms.end());
    printf(":: %i Randomness variations!  :: \n", (int)BestRandoms.size());
    for_(BestRandoms.size()) {
        auto& R = BestRandoms[i]; 
        printf("  %s (%f)\n", R.Name.c_str(), R.Score);
    }

    return 0;
}


