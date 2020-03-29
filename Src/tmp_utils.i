

Ooof bool chduuhh(const char* s) {
	// avoid stupid warnings... sigh.
	int Error = chdir(s);
	if (Error) {
		printf("Can't chdir to: %s (error %s)\n", s, strerror(errno));
	}
	return !Error;
}

Ooof bool mkduuhh(const char* s) {
	const int UnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
	// avoid stupid warnings... sigh.
	int Error = mkdir(s, UnixMode);
	if (Error) {
		printf("Can't mkdir: %s (error %s)\n", s, strerror(errno));
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

