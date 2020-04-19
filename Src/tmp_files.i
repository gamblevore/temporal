


void OpenFile(string Path) {
#if defined(__APPLE__) && defined(__MACH__) && (defined(__i386__) || defined(__x86_64__) || defined(__amd64__))
	Path = string("open \"") + Path + "\"";
	system(Path.c_str());
#else
	printf("Take a look at output file: %s\n", Path.c_str());
#endif
}


Ooof string GetCWD() {
	cstring c = getcwd(0, 0);
	string s = c;
	free((void*)c);
	return s;
}


Ooof string ResolvePath(string S, bool ErrIfCantFind=true) {
	if (S[0] == '~' and S[1] == '/') {
		S = getenv("HOME") + S.substr(1, S.length()-1);
	}
	auto P = realpath(S.c_str(), 0);
	if (P) {
		string Result = P;
		free(P);
		return P;
	}
	if (ErrIfCantFind)
		fprintf(stderr, "Can't resolve: %s (%s)\n", S.c_str(), strerror(errno));
	return "";
}


Ooof string ReadStdin () {
	std::string goddamnit_cpp(std::istreambuf_iterator<char>(std::cin), {}); // C++ is so baaad
	return goddamnit_cpp;
}

Ooof string ReadFile (string name, int MaxLength=1024*1024*256) {
	struct stat sb;
	if (stat(name.c_str(), &sb)==0) {
		if (sb.st_size > MaxLength) {
			fprintf( stderr, "File too big: %s\n", name.c_str());
			return "";
		}

		errno = 0;
		std::ifstream inFile;
		inFile.open(name);
		std::stringstream strStream;
		strStream << inFile.rdbuf();
		if (!errno)
			return strStream.str();
	}
	fprintf(stderr, "Can't read: %s (%s)\n", name.c_str(), strerror(errno));
	return "";
}


Ooof bool WriteFile (u8* Data, int N, string Name) {
	FILE* oof = fopen(Name.c_str(), "wb");
	if (oof) {
		int N2 = (int)fwrite(Data, 1, N, oof);
		fclose(oof);
		if (N2 == N) return true;
	}
	fprintf(stderr, "Can't write: %s (%s)\n", Name.c_str(), strerror(errno));
	return false;
}



Ooof bool chduuhh(cstring s) {
	// avoid stupid warnings... sigh.
	int Error = chdir(s);
	if (Error) {
		Error = errno;
		fprintf(stderr, "Can't chdir to: %s (%s)\n", s, strerror(Error));
	}
	return !Error;
}


Ooof bool fexists(cstring s) {
	// file-systems suck... lol.
	struct stat sb;
	int OldErr = errno;
	int Error = stat(s, &sb);
	bool NotExists = (Error != 0  and  errno==ENOENT);
	errno = OldErr; // reset to 0, hopefully.
	return !NotExists;
}


Ooof bool fisdir(cstring s) {
	struct stat sb;
	int Error = stat(s, &sb);
	return !Error and S_ISDIR(sb.st_mode);
}


Ooof bool mkduuhh(cstring s) {
	// avoid stupid warnings... sigh.
	struct stat sb;
	int Error = stat(s, &sb);

	if ((Error and errno==ENOENT) or !S_ISDIR(sb.st_mode)) {
		const int UnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
		Error = mkdir(s, UnixMode);
	}

	if (Error) {
		Error = errno;
		fprintf(stderr, "Can't mkdir: %s (%s)\n", s, strerror(Error));
	}
	return !Error;
}

Ooof bool MakePath(const std::vector<string>& Pieces) {
	string FullPath;
	for (auto& Item : Pieces) {
		if (Item == "") continue;
		if (FullPath == "" and Item == "~") {
			FullPath = ResolvePath("~/");
		} else {
			FullPath += "/" + Item;
		}
		auto P = FullPath.c_str();
		if (fisdir(P))
			continue;
		if (!mkduuhh(P))
			return false;
	}

	return true;
}


Ooof std::vector<string> PathSplit(string S) {
	std::stringstream	Pieces(S);
	std::string			Item;
	std::vector<string> Result;
	while (std::getline(Pieces, Item, '/')) {
		Result.push_back(Item);
	}
	return Result;
}


Ooof bool MakePath(string P) {
	auto R = PathSplit(P);
	return MakePath(R);
}

Ooof bool MakePathFor(string P) {
	auto S = PathSplit(P);
	S.pop_back();
	return MakePath(S);
}


Ooof string Suffix(string S) {
	auto i = S.length();
	while (i >= 1) {
		auto C = S[--i]; 
		if (C == '.')
			return S.substr(i+1, S.length());
		  else if (C=='/')
			return "";
	}
	return "";
}

Ooof string SlashTerminate(string s) {
	if (s != "" and s[s.length()-1]!='/')
		return s + "/";
	return s;
}

Ooof bool EndsWith(string s, string find) {
	auto nf = find.length();
	auto ns = s.length();
	s = s.substr(ns - nf, nf);
	return s == find;
}
