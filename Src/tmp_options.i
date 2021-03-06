


static u8	HexTest[256];
cstring HexChars  =  "0123456789abcdef";

Ooof int InPlaceConvertToHex (u8* Data, int N) {
	u8* Read = Data + N;
	u8* Write = Data + N*2;
	while (Read > Data) {
		u8 c = *--Read;
		*--Write = HexChars[c&15];
		*--Write = HexChars[c>>4];
	} 
	return N*2;
}


Ooof string HexString(string s) {
	int n = (int)s.length();
	s.resize(n*2);
	InPlaceConvertToHex((u8*)s.c_str(), n);
	return s;
}


Ooof int SplitUnit (string L) {
	for_(L.size())
		if (L[i] < '0' or L[i] > '9')
			return i;
	return (int)L.size();
}


Ooof char lower (char a) {
	if (a >= 'A' and a <= 'Z')
		return a + ('a'-'A');
	return a;
}

Ooof bool IsLower (char a) {
	return (a >= 'a' and a <= 'z');
}

Ooof bool IsUpper (char a) {
	return (a >= 'A' and a <= 'Z');
}

Ooof bool IsDigit (char a) {
	return (a >= '0' and a <= '9');
}



// why am i forever doing this low-level shit?
Ooof const u8* HexCharsInit () {
	u8* T = HexTest;
	if (T['9']!=9) {
		memset(T, 255, 256);
		for_(10) {
			T[i+'0'] = i;
		}
		for_(6) {
			T[i+'a'] = i+10;
			T[i+'A'] = i+10;
		}
		T[' ' ] = 32;
		T['\t'] = 32;
		T['\n'] = 32;
	}
	return T;
}


Ooof u8 HexRead (u8* Data) {
	const u8* T = HexTest;
	return (T[Data[0]] << 4) | (T[Data[1]]);
}


Ooof int HexCleanup (u8* Write, u8* Addr, u32 Len) {
	// and this low-level shit too?
	auto T = HexCharsInit();
	int Count = 0;
	u32 Byte = 0;
	
	for_(Len) {
		u8 Value = T[Addr[i]];
		if (Value < 16) {
			Byte = (Byte << 4) | Value;
			Count++;
		}
		if (!(Count % 2)) {
			*Write++ = Byte;
		}
	}
	
	return Count/2;
}


Ooof bool AllHex (u8* Addr, u32 Len) {
	auto T = HexCharsInit();
	
	for_(Len)
		require (T[Addr[i]] != 255);
	return true;
}



Ooof std::vector<string> ArgArray(cstring argv[]) {
	std::vector<string> Result;
	int i = 1;
	while (argv[i]) {
		Result.push_back(argv[i]);
		i++;
	}
	return Result;
}


Ooof bool cmatchi (cstring a, cstring b) {
	if (!a or !b)
		return a==b;

	while (true) {
		char A = lower(*a++);
		char B = lower(*b++);
		if (!A or !B)
			return A==B;
		if (A != B)
			return false;
	}
	
	return true;
}

Ooof bool matchi (string a, string b) {
	return cmatchi(a.c_str(), b.c_str());
}


Ooof string ArrRead (StringVec& S, int i) {
	if (S.size() > i)
		return S[i];
	return "";
}

Ooof int ParseLength (string L) {
	int mul = 0;
	int spl = SplitUnit(L);
	string U = L.substr(spl, (int)L.size());
	int UL = (int)U.size() - 1;
	auto Last = U[UL];
	if (Last == 'b' or Last == 'B')
		U = U.substr(0, UL);

	if (U == "")
		mul = 1;
	  else if (U == "k" or U == "K")
		mul = 1024;
	  else if (U == "m" or U == "M")
		mul = 1024 * 1024;
	  else
		std::cerr << "Can't use unit: " << U << "\n";

	if (mul) {
		string Amount = L.substr(0, spl);
		if (Amount.size())
			return atoi(Amount.c_str()) * mul;
	}

	errno = ArgError;
	return 0;
}


Ooof FILE* CmdArgFile (string FileOut, FILE* Default) {
	if (FileOut == "" or FileOut == "-")
		return Default;

	auto Dest = fopen(FileOut.c_str(), "w");
	if (Dest)
		return Dest;

	std::cerr << "Can't open: " << FileOut;
	return 0;
}


Ooof int Num (string s, bool& OK) {
	const char* str = s.c_str();
	char* Out = 0;
	int OldErr = errno;
	errno = 0;
	auto Result = (int)strtol(str, &Out, 10);
	OK = !errno;
	errno = OldErr;
	return (int)Result;
}


Ooof string GetArg (StringVec& V, int i) {
	if (i < V.size()) {
		return V[i];
	}
	errno = ArgError;
	return "";
}

Ooof string UnHexString(const string& s) {
	string d;
	d.resize((int)s.length()/2);
	HexCleanup((u8*)d.c_str(), (u8*)s.c_str(), (int)s.length());
	return d;
}

Ooof string CPrint(string s) {
	bool Escaped = false;
	std::stringstream Data;
	Data << '"';
	auto T = HexCharsInit();
	
	for (auto c2: s) {
		u8 c = (u8)c2;
		if (c < 32 or c >= 128 or c == '"' or c == '\\' or c=='\?') {
			if (!c) {
				Data << "\\0";
			} else {
				Data << "\\x";
				Data << HexChars[c>>4];
				Data << HexChars[c&15];
			}
			Escaped = true;
		} else {
			if (Escaped) {
				if (T[c]==255) {
					Escaped = false;
				} else {
					Data << '"';
					Data << '"';
				}
			}
			Escaped = false;
			Data << c;
		}
	}
	Data << '"';
	string s2 = Data.str();
	return s2;
}

//\" = quotation mark (backslash not required for '"')
//\? = question mark (used to avoid trigraphs)
//\\ = backslash
