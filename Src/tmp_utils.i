


Ooof std::vector<string> Split(string S) {
	std::stringstream	Pieces(S);
	std::string			Item;
	std::vector<string> Result;
	while (std::getline(Pieces, Item, '/')) {
		Result.push_back(Item);
	}
	return Result;
}

