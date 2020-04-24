

// i hate C-style for-loops! XD

#define for_(count)			for (int i = 0; i < count; i++)
#define FOR_(var, count)	for (int var = 0; var < count; var++)
#define require(expr)		if (!(expr)) {return {};}
#define New(x)				std::make_shared<x>()
#define New2(x,a)			std::make_shared<x>(a)
#define New3(x,a,b)			std::make_shared<x>(a,b)
#define New4(x,a,b,c)		std::make_shared<x>(a,b,c)
#define Now()				std::chrono::high_resolution_clock::now()
#define self				(*this)
#define ChronoLength(Start)	(std::chrono::duration_cast<std::chrono::duration<float>>(Now() - Start).count())
#if defined(DEBUG) && !defined(__ANDROID__)
	#define debugger asm("int3")
	#define DEBUG_AS_NUM 1
#else
	#define debugger
	#define DEBUG_AS_NUM 0
#endif
#define Ooof				[[maybe_unused]] static
#define test(cond)			if (!(cond)) {debugger;}
#define sizecheck(a,b)		static_assert (sizeof(a)==b, "bad size!") // sizecheck
#define     ArgError			-5555
