
//#ifdef __SHELL_TOOL__ // just use anyway

struct DirReader {
	DIR*		D;
	dirent*		Child;
	
	DirReader(string c) {
		D = opendir(c.c_str());
		Child = 0;
	}
	~DirReader() {
		if (D)
			closedir(D);
	}
	int Next() {
		require (D);
		while ((Child = readdir(D))) {
			const char* P = Child->d_name;
			if (!strcmp(P, ".") or !strcmp(P, ".."))
				continue;
			return true;
		}
		return false;
	}
	string Name() {
		require(D and Child);
		const char* P = Child->d_name;
		return string(P);
	}
};

//#endif
