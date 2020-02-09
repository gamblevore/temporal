

void OpenFile(string Path) {
#if __linux__
	printf("Take a look at output file: %s\n", Path.c_str());
#else
	Path = string("open \"") + Path + "\"";
	IgnoredError = system(Path.c_str());
#endif
}


static void WriteImg (u8* Data, int N, string Name) {
	stbi_write_png_compression_level = 9;
	int W = sqrt(N);
	stbi_write_png(Name.c_str(), W, W, 1, Data, W);
}


static string ReadFile (string name, int MaxLength) {
	struct stat sb;
	require (stat(name.c_str(), &sb)==0);
	if (sb.st_size > MaxLength) {
		fprintf( stderr, "File too big: %s\n", name.c_str());
		return "";
	}

	std::ifstream inFile;
	inFile.open(name);
	std::stringstream strStream;
	strStream << inFile.rdbuf();
	return strStream.str();
}


static void WriteFile (u8* Data, int N, string Name) {
	FILE* oof = fopen(Name.c_str(), "wb");
	if (oof) {
		fwrite(Data, 1, N, oof);
		fclose(oof);
	}
}


static void HTMLImg(std::ofstream& ofs, ref(GenApproach) V) {
	GenApproach& R = *V;
	ofs << "<td>";
	if (R.Stats.Length and !R.Stats.Type) {
		ofs << "<div class='img_ontop'>\n";
		ofs << "<img class='main'  src='" + R.FileName()+"' />\n";
		ofs << "<img class='histo' src='" + R.FileName("h") + "' />\n";
		ofs << "</div><br/>\n";
	}

	ofs << R.Name();
	ofs << ((R.Fails) ? " ❌" : "");
	int W = R.Stats.WorstIndex - 1;
	int F = R.Stats.FailedIndexes;
	for_ (5) {
		if (i == W)  ofs << "<b>";
		ofs << "<br/>" + ScoreNames[i].substr(0,4) + " ";
		ofs << std::fixed << std::setprecision(3) << R[i];
		ofs << (((1<<i) & F) ? " ❌" : "");
		if (i == W)  ofs << "</b>";
	}
	
	ofs << "<br/>";
	ofs << "</td>\n";
}


void BookHitter::CreateHTMLRandom(ApproachVec& V, string FileName, string Title) {
	printf(":: %li Randomness variations!  :: \n", V.size());

	string Path = string(getcwd(0, 0)) + string("/") + FileName;
	std::ofstream ofs;
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
	height: 128px;
	width:  128px;
}
/*CSS*/
.img_ontop {
	position: relative;
	top: 0;
	left: 0;
}
.main {
	position: relative;
	top: 0;
	left: 0;
}
.histo {
	position: absolute;
	bottom: 0px;
	right: 0px;
	height: 32px;
	width:  32px;
	border: 1px gray solid;
}
.histo:hover {
	height: 128px;
	width:  128px;
	transition: 0.25s;
}
	</style>
</head>
<body>
<table>
<tr>
)";

	const char* Row = "</tr>\n\n<tr><td><br/></td></tr><tr>\n"; 
	auto t = std::time(nullptr);
	auto tm = *std::localtime(&t);
	
	ofs << "<p>Created on: ";
	ofs << std::put_time(&tm, "%d %b %y, %H:%M:%S");
	ofs << Row;

	HTMLImg(ofs, MinMaxes[0]);
	HTMLImg(ofs, MinMaxes[1]);
	ofs << Row;
	
	HTMLImg(ofs, MinMaxes[2]);
	HTMLImg(ofs, MinMaxes[3]);
	ofs << Row;

	int i = 0;
	for (auto R : V) {
		if (!R->Stats.Length) continue;
		if (i++ % 8 == 0) ofs << Row;
		HTMLImg(ofs, R);
	}
	
	ofs << R"(
</tr>
</table>
</body>
</html>)";
	
	ofs.close();
	
	if (LogOrDebug())
		FilesToOpenLater.push_back(Path);
	  else
	    printf("Debug Steve output at: %s\n", Path.c_str());
}


void BookHitter::CreateDirs() {
	if (CreatedDirs) {
		return;
	}
	CreatedDirs = true;
	int UnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
	IgnoredError = mkdir("steve_output",  UnixMode);
	IgnoredError = chdir("steve_output");
	IgnoredError = mkdir("time_imgs",	  UnixMode);
}


void BookHitter::LogApproach(const char* Debiased="") {
	if (LogOrDebug()) {
		CreateDirs();
		int N = App->Stats.Length;
		WriteImg(Extracted(), N, App->FileName(Debiased));
	}
}
