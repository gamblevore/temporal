
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
#include <unistd.h>
#include <vector>
#include <fstream>

#define __TEMPORAL_RESEARCH_IMPLEMENTATION__
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBIW_WINDOWS_UTF8
#include "temporal_research.h"
#include "stb_image_write.h"





///////// STRUCTS ////////
using std::ofstream;
typedef std::vector<unsigned char>  ByteArray;
struct ScoreAndName {
    double      Score;
    ByteArray*  Data;
    std::string Name;
    bool operator<(const ScoreAndName &rhs) const { return Score < rhs.Score; }
};


///////// GLOBALS ////////
static std::vector<ScoreAndName> BestRandoms;
static std::vector<ScoreAndName>   Patterns;




int WriteStride (u8* Line, int x, int n, int Value, int W) {
    int x2 = x + n;
    while (x < x2 and x < W) {
        Line[x++] = Value;
    }
    return x2;
}


ByteArray* PatternStride( int White, int Black, int Gap, int W) {
    ByteArray* Arr = new ByteArray(W*W);
    std::string Name = "pat";
    Name += std::to_string(White); Name += "_";
    Name += std::to_string(Black); Name += "_";
    Name += std::to_string(Gap); 
    ScoreAndName Sc = {0.0f, Arr, Name};
    Patterns.push_back(Sc);
    
    if (White and Black) {
        FOR_(y, W) {
            int IsGap = (y/Black) % 2;
            int x = IsGap*Gap;
            u8* Line = &((*Arr)[y*W]);
            while (x < W) {
                x = WriteStride(Line, x, White, 255, W);
                x = WriteStride(Line, x, Black, 0, W);
            }
        }
    }

    return Arr;
}


///////// CODE ////////
static void GeneratePatterns(int W) {
    PatternStride(1,1,1,    W);
    PatternStride(1,1,0,    W);
    PatternStride(4,4,4,    W);
    PatternStride(4,4,0,    W);
    PatternStride(16,16,16, W);
    PatternStride(16,16,0,  W);
    auto & P = *PatternStride(0,0,0, W);
    
    int c = W / 2;
    int Hits = 0;
    double RSq = (double)W*W / (2.0 * M_PI);
    // πrr = c_area
    // ww =  sq_area
    // c_area = sq_area / 2 --> rr = ww / 2π
    
    FOR_ (y, W) {
        FOR_ (x, W) {
            double DistSq = pow(x-c,2) + pow(y-c,2); 
            if (DistSq <= RSq) {
                int Coord = x + y*W;
                Hits++;
                P[Coord] = 255;
            }
        }
    }

    int ExpectedHits = (W*W/2);
    u8 WriteColor = 255*(Hits < ExpectedHits);
    u8 FindColor = 255-WriteColor;
    int Adjust = abs(Hits-ExpectedHits);
    for_(P.size()) {
        if (P[i] == FindColor) {
            P[i] = WriteColor;
            if (--Adjust <= 0) {break;}
        }
    }
}


static void SavePatterns(int W) {
    for (auto& Info : Patterns) {
        std::string Path = "patterns/" + Info.Name + ".png";
        auto &Arr = *Info.Data;
        u8* First = &(Arr[0]);
        stbi_write_png(Path.c_str(), W, W, 1, First, W);
    }
}


static void PostProcess (TemporalGeneratorParams& P, ByteArray& Bytes, int Mod) {
    auto Data = P.Out;
    
    for_(Bytes.size()) {
        auto V = *Data++;
        if (Mod) {
            V = (V % Mod) * (256/Mod);
        }
        V = (V % 2)*255;
        Bytes[i] = V;
    }
}



static std::string Outputfile (TemporalGeneratorParams& P, ByteArray& Data, int W, int Mod) {
    std::string name = "";
    name += P.Stats->Name;
    name += std::to_string(P.RepetitionsPerSample);
    if (Mod) {
        name += "_";
        name += std::to_string(Mod); 
    }
    stbi_write_png_compression_level = 9;

    std::string PngPath = "time_imgs/";
    PngPath += name;
    PngPath += ".png";
    stbi_write_png(PngPath.c_str(), W, W, 1, &Data[0], W);
    
    std::string RawPath = "raw_data/";
    RawPath += name;
    RawPath += ".raw";

    auto f = stbiw__fopen(RawPath.c_str(), "wb");
    if (f) {
        fwrite(&Data[0], 1, Data.size(), f);
        fclose(f);
    }
    return name;
}


static int ReadRandCoord(ByteArray& Bytes, int Start, int Max) {
    int Coord = 0;
    for_ (Max) {
        if (Bytes[i+Start]) {
            Coord |= 1;
        }
        Coord <<= 1;
    }
    return Coord;
}


static double HitScore(int Hits, ByteArray& Bytes) {
    int Expected = (int)Bytes.size()/2;
    int Diff = Expected - Hits;
    return (double)abs(Diff);
}


static double DetectOneCoord (ByteArray& Bytes, int Mod, ByteArray& Pattern) {
    // So... use some kinda monte-carlo test to see if these are the same?
    int Hits = 0;
    int Max = log2(Bytes.size());
    for (int i = 0; i < Bytes.size(); i+=Max) {
        auto Coord = ReadRandCoord(Bytes, i, Max);
        if (Pattern[Coord]) {
            Hits++;
        }
    }
    
    return HitScore(Hits, Bytes);
}


static double DetectOne (ByteArray& Bytes, int Mod, ByteArray& Pattern) {
    // So... use some kinda monte-carlo test to see if these are the same?
    int Hits = 0;
    for (int i = 0; i < Bytes.size(); i++) {
        bool B = Bytes[i];
        bool P = Pattern[i];
        if (B == P) {
            Hits++;
        }
    }
    
    return HitScore(Hits, Bytes);
}


static double DetectRandomness (ByteArray& Bytes, int Mod) {
    // mod is to give an idea of where the byte values lie between...
    double A = 0.0;
    double B = 0.0;
    for (auto &P: Patterns) {
        A = std::max(A, DetectOne(Bytes, Mod, *P.Data));
        B = std::max(B, DetectOneCoord(Bytes, Mod, *P.Data));
    }
    return B;
}


void CreateHTMLRandoms() {
    std::ofstream ofs;
    ofs.open ("scoring.html");
    
    ofs << "<html><head><title>Randomness scoring</title></head><body>\n";
    
    for( auto& R: BestRandoms) {
        ofs << "<p><img src='time_imgs/";
        ofs << R.Name;
        ofs << ".png'/></p>\n\n";
    }
    ofs << "</body></html>\n";
    
    ofs.close();
}

static void TryOutputFile (TemporalGeneratorParams& P, ByteArray& Bytes, int W, int Mod) {
    PostProcess(P, Bytes, Mod);
    double Score = DetectRandomness(Bytes, Mod);
    auto name = Outputfile(P, Bytes, W, Mod);
    BestRandoms.push_back({Score, &Bytes, name});
}



int main (int argc, const char * argv[]) {
    puts(
R"(Research into temporal-random-number generation.

Generates png files in your current directory, for you to check if the randomness "seems good" or not.

The idea is to use the randomness in "how long" an instruction takes, as a source of physically based randomness.

No idea if this randomness is "good" or not, yet. It has promise, but there are a lot of questions to answer!
)");

    int StupidUnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
    mkdir("time_output", StupidUnixMode);
    chdir("time_output");
    mkdir("time_imgs", StupidUnixMode);
    mkdir("raw_data", StupidUnixMode);
    mkdir("patterns", StupidUnixMode);

    const int W = 256;
    const int N = W*W;
    ByteArray Bytes (N);
    
    GeneratePatterns(W);
    SavePatterns(W);

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
    
    printf(":: %i Randomness variations!  :: \n", (int)BestRandoms.size());
    std::sort(BestRandoms.begin(), BestRandoms.end());
    CreateHTMLRandoms();

    chdir(".."); // be polite

    return 0;
}


