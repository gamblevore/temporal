

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
			cstring P = Child->d_name;
			if (!strcmp(P, ".") or !strcmp(P, ".."))
				continue;
			return true;
		}
		return false;
	}
	string Name() {
		require(D and Child);
		cstring P = Child->d_name;
		return string(P);
	}
};


struct ArchiveFile;
struct GenApproach;
