
/*
	// steve-lists
	bool1, float213, int100, etc
	atomic9, float7, int3
*/

const string SteveListsFile = "/var/tmp/steve.txt";
const string SteveListsInitFile = "/var/tmp/steve_init.txt";


void BookHitter::SaveLists() {
	struct stat sb;
	const char* ParentDir = "/var/tmp/";
	if (stat(ParentDir, &sb) or !S_ISDIR(sb.st_mode)) { // doesn't exist :(
		printf("Can't access folder: %s \n", ParentDir);
		return;
	}

	if (CPU_Modes.size() > 16)
		CPU_Modes.resize(16);

	std::ofstream ofs;
	ofs.open (SteveListsFile);
	ofs << "// steve-lists\n";
	for (auto list: CPU_Modes) {
		for (auto item : *list) {
			ofs << item->Name();
			ofs << ",";
		}
		ofs << "\n";
	}
	ofs.close();
}


bool BookHitter::LoadLists() {
	if (LoadListsSub(SteveListsInitFile))
		return true;
	if (LoadListsSub(SteveListsFile))
		return true;
	return false;
}


bool BookHitter::LoadListsSub(string Path) {
	auto Data = ReadFile(Path, 16 * 1024);
	if (!Data.length())
		return false;

	CPU_Modes = {};

	std::stringstream Lines(Data);
	std::string Line;

	while (std::getline(Lines, Line, '\n')) {
		if (Line[0] == '/') continue;
		std::stringstream Items(Line);
		auto V = New(ApproachVec);

		std::string Item;
		while (std::getline(Items, Item, ',')) {
			auto Found = (*this)[Item];
			if (Found) { 
				V->push_back(Found);
				if (V->size() >= 16)
					break;
			} else if (Item.length()) {
				printf("Can't find temporal-generator: %s\n", Item.c_str());
			}
		}
		
		if (!V->size()) continue;
		CPU_Modes.push_back(V);
		if (CPU_Modes.size() >= 16) break;
	}
	
	return true;
}


/*
function LoadLists {
// Speedie... smaller and faster
	.CPU_Modes = []
	|| Data = ListsFile.ReadFile(16*1024)
	for line in Data.lines
		|| V = ApproachVec.new
		for item in line.split(",")
			|| Found = self[Item] #continue_with_error "Can't find temporal-generator: $Item"
			V ~ Found
			if V.Count >= 16 : exit
		
		if V
			.CPU_Modes ~ V
			if .CPU_Modes.count >= 16 : exit
}
*/


