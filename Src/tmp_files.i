

void OpenFile(string Path) {
#if __linux__
	printf("Take a look at output file: %s\n", Path.c_str());
#else
	Path = string("open \"") + Path + "\"";
	system(Path.c_str());
#endif
}


Ooof string GetCWD() {
	const char* c = getcwd(0, 0);
	string s = c;
	free((void*)c);
	return s;
}


Ooof string ResolvePath(string S) {
	if (S=="-")
		return S;
	auto P = realpath(S.c_str(), 0);
	if (P) {
		string Result = P;
		free(P);
		return P;
	}
	return "";
}


Ooof string ReadStdin () {
	std::string goddamnit_cpp(std::istreambuf_iterator<char>(std::cin), {}); // C++ is so baaad
	return goddamnit_cpp;
}

Ooof string ReadFile (string name, int MaxLength) {
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


Ooof void WriteFile (u8* Data, int N, string Name) {
	FILE* oof = fopen(Name.c_str(), "wb");
	if (oof) {
		fwrite(Data, 1, N, oof);
		fclose(oof);
	}
}



Ooof bool chduuhh(const char* s) {
	// avoid stupid warnings... sigh.
	int Error = chdir(s);
	if (Error) {
		Error = errno;
		fprintf(stderr, "Can't chdir to: %s (%s)\n", s, strerror(Error));
	}
	return !Error;
}


Ooof bool fexists(const char* s) {
	// file-systems suck... lol.
	struct stat sb;
	int OldErr = errno;
	int Error = stat(s, &sb);
	bool NotExists = (Error != 0  and  errno==ENOENT);
	errno = OldErr; // reset to 0, hopefully.
	return !NotExists;
}


Ooof bool fisdir(const char* s) {
	struct stat sb;
	int Error = stat(s, &sb);
	return !Error and S_ISDIR(sb.st_mode);
}


Ooof bool mkduuhh(const char* s) {
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
		FullPath += "/" + Item;
		auto P = FullPath.c_str();
		mkduuhh(P);
		struct stat sb;
		if (stat(P, &sb)) {
			fprintf(stderr, "Path %s can't be accessed.\n", P);
			return false;
		}
	}

	return true;
}
