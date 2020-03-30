

Ooof bool chduuhh(const char* s) {
	// avoid stupid warnings... sigh.
	int Error = chdir(s);
	if (Error) {
		Error = errno;
		printf("Can't chdir to: %s (%s)\n", s, strerror(Error));
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
		printf("Can't mkdir: %s (%s)\n", s, strerror(Error));
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
			printf("Path %s can't be accessed.\n", P);
			return false;
		}
	}

	return true;
}


Ooof std::vector<string> Split(string S) {
	std::stringstream	Pieces(S);
	std::string			Item;
	std::vector<string> Result;
	while (std::getline(Pieces, Item, '/')) {
		Result.push_back(Item);
	}
	return Result;
}

