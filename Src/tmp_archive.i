

struct DecodedItem {
	int		i;
	string	Src;
	string  Found_Data;
	string	Found_Path;
	
	DecodedItem() {
		i = 0;
	}
	int Find(char s) {
		if (i<0) return -1;
		int Found = (int)Src.find(s, i+1);
		i = Found;
		return Found;
	}
	bool OK() {
		return i >= 0;
	}
	string Str(int a, int b) {
		a++;
		return Src.substr(a, b-a);
	}
};


struct Archive;
struct ArchiveFileOofer;
struct ArchiveFile {
	string				Path;
	std::stringstream	Data;
	Archive*			Parent;
	bool				Closed;
	bool				OpenMe;
	
	ArchiveFile (Archive* P, string Where) {
		Parent = P;
		Path = Where;
		Closed = false;
		OpenMe = false;
	}
	
	~ArchiveFile() {
		Close();
	}

	
	void operator << (string s) {
		Data << s;
	}
	void operator << (const char s) {
		Data << s;
	}
	string ReadAll() {
		string result = Data.str();
		Data.str("");
		return result;
	}

	void				Close();
	string				FullPath();
	ArchiveFileOofer	Oof();
};


struct ArchiveFileOofer {
	ArchiveFile* CppSuxx;
	void operator << (string s) {
		CppSuxx->Data << s;
	}
	void operator << (const char s) {
		CppSuxx->Data << s;
	}
	void Close() {
		CppSuxx->Close();
	}
	string Path() {
		return CppSuxx->Path;
	}
	std::stringstream& Oof() {
		return CppSuxx->Data;
	}
};


ArchiveFileOofer ArchiveFile::Oof() {
	ArchiveFileOofer Result;
	Result.CppSuxx = this;
	return Result;
}


struct Archive {
	string							Path;
	std::stringstream				ConCat;
	std::vector<ref(ArchiveFile)>	Files;
	bool							WriteToDisk;
	bool							OK;
	bool							Opened;
	bool							Closed;
	bool							GotStuff;
	
	void Init(string Where="") {
		Path = SlashTerminate(Where);
#if defined(__SHELL_TOOL__)
		WriteToDisk = true;
#else
		WriteToDisk = false;
#endif
		OK = true;
		Opened = false;
		Closed = false;
		GotStuff = false;
	}
	
	ArchiveFile& AddFile (string Where, bool OpenMe=false) {
//		if (EndsWith(Where, ".html.png"))
//			debugger;
		auto F = std::make_shared<ArchiveFile>(this, Where);
		F->OpenMe = OpenMe;
		Files.push_back(F); // memory management
		return *F;
	}
	
	void Open() {
		if (OK and !Opened) {
			if (!WriteToDisk) {
				ConCat << "{\n";
			} else if (OK) {
				OK = MakePath(Path);
			}
			Opened = OK;
		}
	}
	
	void Close() {
		if (!Closed) {
			Closed = true;
			if (!WriteToDisk) {
				ConCat << "\n}\n";
			}
		}
	}
	
	void Write(ArchiveFile& F) {
		if (!OK) {debugger; return;}
		string Data = F.ReadAll();
		if (WriteToDisk) {
			string P = Path + F.Path;
			OK = MakePathFor(P);
			OK = WriteFile((u8*)Data.c_str(), (int)Data.length(), P) and OK;
		} else {
/* {
	"a/b/c.file" : "DataHEX"
}*/
			if (GotStuff)
				ConCat << ",\n";
			GotStuff = true;
			ConCat << "\t\"";
			ConCat << F.Path;
			ConCat << "\": \"";
			ConCat << HexString(Data);
			ConCat << "\"";
		}
	}


	static bool GetNext(DecodedItem& Item) {
		int NameStart = Item.Find('"');
		int NameEnd = Item.Find('"');
		Item.Find(':');
		int DataStart = Item.Find('"');
		int DataEnd = Item.Find('"');
		require (Item.OK());
		
		Item.Found_Data = UnHexString(Item.Str(DataStart, DataEnd));
		Item.Found_Path = Item.Str(NameStart, NameEnd);
		return true;
		// then unhex! and store!
	}
	
	
	static void WriteItem(DecodedItem& Item, string Path) {
		string oof = Item.Found_Data;
		Path += Item.Found_Path;
		puts(Path.c_str());
		if (MakePathFor(Path))
			WriteFile((u8*)oof.c_str(), (int)oof.length(), Path);
	}
	
	
	static void WriteAnyway(string Data, string Path) {
		DecodedItem Item;
		Path = SlashTerminate(Path);
		Item.Src = Data;
		while (GetNext(Item)) {
			WriteItem(Item, Path);
		}
		// im sad ur PC hate me ;_;
	}
};


void ArchiveFile::Close () {
	if (!Closed) {
		Closed = true;
		Parent->Write(self);
	}
}


string ArchiveFile::FullPath() {
	return Parent->Path + Path;
}

