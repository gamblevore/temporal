

#include <sys/stat.h>
#include <unistd.h>
#include <signal.h>
#include <math.h>
#include <stdlib.h>
#include <pthread.h>
#include <limits.h>
#ifdef __APPLE__
	#include <mach/mach_time.h>
#endif
#ifdef __SHELL_TOOL__
	#include <fcntl.h>
	#include <dirent.h>
#endif

#include <cmath>
#include <fstream>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <ctime>
#include <chrono>
#include <atomic>
#include <algorithm>
#include <random>
#include <memory>
#include <vector>
#include <map>

