
bool MakePath(const std::vector<string>& Pieces) {
	string FullPath;
	const int UnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
	for (auto& Item : Pieces) {
		FullPath += "/" + Item;
		auto P = FullPath.c_str();
		IgnoredError = mkdir(P, UnixMode);
		struct stat sb;
		IgnoredError = stat(P, &sb); 
		if (IgnoredError) {
			printf("Path %s can't be accessed.\n", P);
			return false;
		}
	}

	return true;
}


std::vector<string> Split(string S) {
	std::stringstream	Pieces(S);
	std::string			Item;
	std::vector<string> Result;
	while (std::getline(Pieces, Item, '/')) {
		Result.push_back(Item);
	}
	return Result;
}

