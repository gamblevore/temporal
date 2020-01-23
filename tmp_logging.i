

int IgnoredError;

void OpenFile(string Path) {
	Path = string("open \"") + Path + "\"";
	IgnoredError = system(Path.c_str());
}


static void WriteImg (u8* Data, int N, string Name) {
	stbi_write_png_compression_level = 9;
	int W = sqrt(N);
	stbi_write_png(Name.c_str(), W, W, 1, Data, W);
}


static string ReadFile (string name) {
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


static void HTMLImg(std::ofstream& ofs, GenApproach* V) {
	GenApproach& R = *V;
	ofs << "<td>";
	if (R.Stats.Length and !R.Stats.Type)
		ofs << "<img src='" + R.FileName() + "'/><br/>";

	ofs << R.Name();
	int W = R.Stats.WorstIndex - 1;
	for_ (5) {
		if (i == W)  ofs << "<b>";
		ofs << "<br/>" + ScoreNames[i].substr(0,4) + " ";
		ofs << std::fixed << std::setprecision(3) << R[i];
		if (i == W)  ofs << "</b>";
	}
	
	ofs << ((R.Fails) ? "<br/>fail" : "");
	ofs << "<br/>";
	ofs << "</td>\n";
}

void BookHitter::CreateHTMLRandom(ApproachVec& V, string FIleName) {
	printf(":: %li Randomness variations!  :: \n", V.size());

	string Path = string(getcwd(0, 0)) + string("/") + FIleName;
	std::ofstream ofs;
	ofs.open (Path.c_str());
	
	ofs << R"(<html>
<head>
	<title>Fatum Temporal Randomness Test</title>
	<style>

body {
	background: black;
	color: white;
}
img {
	height: 128px;
	width:  128px;
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
		OpenFile(Path);
	  else
	    printf("Debug Steve output at: %s\n", Path.c_str());
}


static void CreateDirs() {
	int UnixMode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH; // oof unix.
	IgnoredError = chdir("/tmp");
	IgnoredError = mkdir("steve_output", UnixMode);
	IgnoredError = chdir("steve_output");
	IgnoredError = mkdir("time_imgs",	  UnixMode);
}

