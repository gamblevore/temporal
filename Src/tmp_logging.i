

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


static void HTMLImg(std::ofstream& ofs, GenApproach* V) {
	GenApproach& R = *V;
	if (!R.UseCount) return;
	ofs << "<td>";
	if (R.Stats.Length and !R.Stats.Type) {
		ofs << "<div class='img_ontop'>\n";
		ofs << "<img class='behind'  src='" + R.FileName()    + "' />\n";
//		ofs << "<a target='_' href='"       + R.FileName("p") + "'>";
		if (!R.IsExternal())
			ofs << "<img class='main' src='"    + R.FileName("p") + "' />";
		ofs << "</a>\n";
		ofs << "<img class='histo' src='"   + R.FileName("h") + "' />\n";
		ofs << "</div><br/>\n";
	}

	ofs << R.Name();
	if (!R.Owner->IsRetro()) {
		int W = R.Stats.WorstIndex - 1;
		int F = R.Stats.FailedIndexes;
		ofs << ((F) ? " ❌" : "");
		for_ (5) {
			if (i == W)  ofs << "<b>";
			ofs << "<br/>" + ScoreNames[i].substr(0,5) + " ";
			ofs << std::fixed << std::setprecision(3) << R[i];
			ofs << (((1<<i) & F) ? " ❌" : "");
			if (i == W)  ofs << "</b>";
		}
		ofs << "<br/>";
	}
	
	ofs << "</td>\n";
}


struct HTML_Random {
	string			FileName;
	string			Title;
	std::ofstream	ofs;
	string			Path;
	int				Variations;
	bool			Started;
	BookHitter*		B;


	HTML_Random(string fn, string t, BookHitter* b) {
		FileName = fn;
		Title = t;
		Variations = 0;
		Started = false;
		ofs = {};
		B = b;
	}
	
	
	void Start() {
		if (Started) return; Started = true;
		Path = GetCWD() + string("/") + FileName;
		ofs.open (Path);
	
		ofs << R"(<html>
<head>
	<title>)";
	ofs << Title;
	ofs << R"(</title>
	<style>
body {
	background: black;
	color: white;
}
img {
	height:	128px;
	width:	128px;
	border:	0px;
}
/*CSS*/
.img_ontop {
	position: relative;
	height:	128px;
	width:	128px;
	top:	0;
	left:	0;
}
.main {
	position: absolute;
	top:	0;
	left:	0;
}
.histo {
	position: absolute;
	bottom:	0px;
	right:	0px;
	height:	32px;
	width:	32px;
}
.behind {
	position: absolute;
	top:	0;
	left:	0;
}
.main:hover {
	opacity: 0.0;
	transition: 0.25s;
}
.histo:hover {
	height: 128px;
	width:	128px;
	transition: 0.25s;
}
	</style>
</head>
<body>
<table>
<tr>
)";

		const char* Row = "</tr>\n\n<tr><td><br/></td></tr><tr><td>\n"; 
		auto t = std::time(nullptr);
		auto tm = *std::localtime(&t);
		
		ofs << "<p>Created on: ";
		ofs << std::put_time(&tm, "%d %b %y, %H:%M:%S");
		if (FileName == "scoring.html" or FileName == "temporal.html")
			ofs << "<br/>&nbsp;&nbsp;<a href='scoring.html'>Scoring</a>&nbsp;&nbsp;<a href='temporal.html'>Temporal</a>";
		ofs << "&nbsp;&nbsp;<a href='http://github.com/gamblevore/temporal'>github</a>";
		ofs << "</p>";
		ofs << Row;

		HTMLImg(ofs, B->MinMaxes[0].get());
		HTMLImg(ofs, B->MinMaxes[1].get());
		HTMLImg(ofs, B->MinMaxes[2].get());
		ofs << Row;
	}


	void WriteOne(GenApproach* App) {
		if (!Started) return;
		const char* Row = "</tr>\n\n<tr><td><br/></td></tr><tr>\n";
		if (!App->Stats.Length) return;
		if (Variations % 8 == 0) ofs << Row;
		HTMLImg(ofs, App);

		Variations++;
	}
	

	void Finish() {
		if (!Started) return;
		printf("\n:: %i Randomness variations!  :: \n", Variations);
		
		ofs << R"(
</tr>
</table>
</body>
</html>)";
		
		ofs.close();
		if (B->LogOrDebug())
			FilesToOpenLater.push_back(Path);
		  else
			printf("Debug Steve output at: %s\n", Path.c_str());
	}
};


ref(HTML_Random) BookHitter::HTML(string fn, string t) {
	auto Result = New4(HTML_Random, fn, t, this);
	if (LogOrDebug())
		Result->Start();
	return Result;
}	


void BookHitter::CreateHTMLRandom(ApproachVec& V1, string FileName, string Title) {
	ApproachVec  V2;
	ApproachVec* V = &V1;
	
	// display alpha-sort
	if (IsRetro()) {
		V2 = V1;
		auto Comparer = [] (ref(GenApproach) a, ref(GenApproach) b) {
			return a->Name() < b->Name();
		};

		std::sort(V2.begin(), V2.end(), Comparer);
		V = &V2;
	}
	
	auto html = HTML(FileName, Title);
	for (auto R : *V)
		html->WriteOne(R.get());	
	html->Finish();
}


void BookHitter::CreateDirs() {
	if (CreatedDirs or !LogOrDebug()) return;

	CreatedDirs = true;
	if (fexists("/tmp/")) {
		chduuhh("/tmp/");
	}
	mkduuhh("temporal_scoring");
	chduuhh("temporal_scoring");
	mkduuhh("time_imgs");
}


void BookHitter::TryLogApproach(string Debiased="") {
	if (!LogOrDebug() or NoImgs()) return;
	int N = App->Stats.Length;
	u8* R = Extracted();
	if (Debiased != "")
		WriteColorImg(R, N, App->FileName(Debiased));
	  else
		WriteColorImg(R, N, App->FileName());
}
