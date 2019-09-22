
//
//  Copyright © 2019 Theodore H. Smith
//  Generate temporal number stream.
//  For the fatum project
//  Just fooling around for now!
//  But if useful could be used in almost anything!
//  Even games :3





                                    ////////  HEADER-ONLY ////////


struct TemporalGeneratorStats {
    unsigned int     Lowest;
    unsigned int     Highest;
    double           Average;
    unsigned int     Spikes;
    unsigned int     Measurements;
    unsigned int     AllowedHighest;
    int              Error;
    const char*      Name;
};


struct TemporalGeneratorParams {
    unsigned int*           Out;
    int                     Count;
    int                     RepetitionsPerSample;
    unsigned int            Generator;
    TemporalGeneratorStats* Stats;
};



extern "C" bool tr_generate(TemporalGeneratorParams& In);
extern "C" const char* tr_generator_name(unsigned int i);

enum TemporalGeneratorType {
    TemporalGeneratorTypeInt,
    TemporalGeneratorTypeAtomic,
    TemporalGeneratorTypeFloat,
    TemporalGeneratorTypeBool,
    TemporalGeneratorTypeTime,
    TemporalGeneratorTypeMemory,
    TemporalGeneratorTypeCount,
    TemporalGeneratorTypeError,
};

// fuck for loops! XD
#define for_(count) for (int i = 0; i < count; i++)
#define FOR_(var, count) for (int var = 0; var < count; var++)
#define CArrayLength(s) (sizeof(s)/sizeof(*s))
#define talloc(type,count) ((type*)calloc(sizeof(type), count))

#ifdef __TEMPORAL_RESEARCH_IMPLEMENTATION__ 
#undef __TEMPORAL_RESEARCH_IMPLEMENTATION__
#include <atomic>
#include <math.h>
#include <stdlib.h>
#include <pthread.h>

extern "C" {



                                    //////// IMPLEMENTATION //////// 

//////// utils ////////   
#define gexpect(cond, err) if (!(cond)) {return err;}
#define Time_(R) while (Data < DataEnd) { u32 Start = Time32(); for_(R)
#define TimeEnd ; u32 Finish = Time32(); *Data++ = TimeDiff(Start,Finish);}
#define Gen(name) static u64 name##Generator (u32* Data, u32* DataEnd, u32 Input, int Reps)
#define Max(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })
#define Min(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b; })     


//////// types ////////   
typedef unsigned char     u8;
typedef unsigned short    u16;
typedef unsigned int      u32;
typedef unsigned long int u64;
typedef long int s64;
typedef u64 (*Generator) (u32* Data, u32* DataEnd, u32 Input, int Reps);

struct NamedGenerator {
    Generator   Func;
    const char* Name;
};


//////// time utilities ////////   

static inline u32 rdtscp( u32 & aux ) {
    // remove aux?
    u64 rax, rdx;
    asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
    return (u32)rax;
}

static inline u32 Time32 () {
    u32 T;
    return rdtscp(T);
}

static int TimeDiff (s64 A, s64 B) {
    auto D = B - A;
    if (D < 0) { // wrap around
        D = (B - 0x7fffFFFF) - (A - 0x7fffFFFF);
    }
    return (int)D;
}


//////// generators ////////
Gen(Float) {
    float x = Input + 1;
    float y = Input + 1;
    Time_ (Reps) {
        y = y + 1000.5;
        x = x / 2.0;
        x = fmodf(x,2.0) - (x / 10000000.0);
        x = floor(x)     - (x * 5000000.0);
        x = fminf(x, MAXFLOAT);
        y = fmaxf(y,-MAXFLOAT);
        x += y;
    } TimeEnd
    
    return x;
}


Gen(FloatSame) {
    float x0 = Input + 1;
    float y0 = Input + 1;
    float x = 0;
    float y = 0;
    Time_ (Reps) {
        x = x0;
        y = y0;
        y = y + 1000.5;
        x = x / 2.0;
        x = fmodf(x,2.0) - (x / 10000000.0);
        x = floor(x)     - (x * 5000000.0);
        x = fminf(x, MAXFLOAT);
        y = fmaxf(y,-MAXFLOAT);
        x += y;
    } TimeEnd
    
    return x;
}


Gen(Time) {
    u32 x = Input;
    Time_ (Reps) {
        x = x xor Time32();
    } TimeEnd

    return x;
}


Gen(Bool) {
    bool f = (Input == 0);
    bool t = (((int)Input) < 1);
    
    Time_ (Reps) {
        f = f and t;
        t = t or f;
        t = f or t;
        f = t and f;
    } TimeEnd
    
    return f;
}


Gen(Int) {
    u64 x = Input + 1;
    u64 y = Input + 1;
    Time_ (Reps) {
        y = y + 981723981723;
        x = x xor (x << 63);
        x = x xor (x >> 59);
        x = x xor (x << 5);
        x += y;
    } TimeEnd
    
    return x;
}


std::atomic<u64> ax;
std::atomic<u64> ay;
Gen(Atomic) {
    ax = Input + 1;
    ay = Input + 1;
    Time_ (Reps) {
        ay = ay + 981723981723;
        ax = ax xor (ax << 63);
        ax = ax xor (ax >> 59);
        ax = ax xor (ax << 5);
        ax += ay;
    } TimeEnd
    
    return ax;
}


Gen(Memory) {
    u32 CachedMemory[1024]; // 4KB of data.
    u32 x = Input;
    u32 Place = 0;
    Time_ (Reps) {
        u32 index = Place++ % 1024;
        x = x xor CachedMemory[index];
        CachedMemory[index] = x;
    } TimeEnd
    
    return x;
}


const NamedGenerator GenList[] = {
    {IntGenerator,      "int"},
    {AtomicGenerator,   "atomic"},
    {FloatGenerator,    "float"},
    {FloatSameGenerator,    "floatsame"},
    {BoolGenerator,     "bool"},
    {TimeGenerator,     "time"},
    {MemoryGenerator,   "memory"}
};



u32 CollectStats (u32* Results, int Count, TemporalGeneratorStats& S) {
    S.Measurements += Count;
    S.Lowest = -1;
    for_ (Count) {
        u32 Time = Results[i];
        S.Lowest = Min(S.Lowest, Time);
        S.Highest = Max(S.Highest, Time);
    }
    
    u32 MaxTime = S.Lowest * 5;
    S.AllowedHighest = MaxTime;
    
    for_ (Count) {
        if (Results[i] > MaxTime) {
            Results[i] = MaxTime; // clamp values
            S.Spikes++;
        }
    }

    return S.Lowest;
} 


static int Generate (TemporalGeneratorParams& P) {
    gexpect (sizeof(u32)==4  and  sizeof(int)==4  and  sizeof(u64)==8, -3);
    gexpect (P.Out, -2);
    gexpect (P.Generator < TemporalGeneratorTypeCount, -1);
    gexpect (P.Count >= 128, -1);
    
    
    auto S = P.Stats;
    auto Out = P.Out;
    auto G = GenList[P.Generator];
    auto Fn = G.Func;
    S->Name = G.Name;

    u32* OutEnd = Out + P.Count;
    
    
    (Fn)(Out, OutEnd, 0, P.RepetitionsPerSample); // warmup
    (Fn)(Out, OutEnd, 0, P.RepetitionsPerSample);
    auto L = CollectStats(Out, P.Count, *S);
    
    // rescale
    for_ (P.Count) {
        Out[i] -= L;
    }
    
    return 0;
}


static pthread_t GeneratorThread; // try to get higher priority. better signals.
static void* GenerateWrapper (void* arg) {
    TemporalGeneratorParams* P = (TemporalGeneratorParams*)arg;
    TemporalGeneratorStats& S = *P->Stats;
    sched_param sch = {sched_get_priority_max(SCHED_FIFO)};
    S.Error = pthread_setschedparam(GeneratorThread, SCHED_FIFO, &sch);
    int Err = Generate(*P);
    if (Err) {
        S.Error = Err;
    }
    return 0;
}



const char* tr_generator_name(unsigned int i) {
    if (i < TemporalGeneratorTypeCount) {
        return GenList[i].Name;
    }
    return 0;
}


bool tr_generate(TemporalGeneratorParams& P) {
    int Err = pthread_create(&GeneratorThread, NULL, &GenerateWrapper, &P);
    if (!Err) {
        return !pthread_join(GeneratorThread, 0);
    }
    return false;
}




}

#endif

