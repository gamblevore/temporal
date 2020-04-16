

struct HTML_Random {
	string			FileName;
	string			Title;
//	string			Path;
	ArchiveFileOofer ofs;
	int				Variations;
	bool			Started;
	BookHitter*		B;


	HTML_Random(string fn, string t, BookHitter* b) {
		FileName = fn;
		Title = t;
		Variations = 0;
		Started = false;
		B = b;
	}
	
	void HTMLImg(GenApproach* V) {
		GenApproach& R = *V;
		if (!R.UseCount) return;
		ofs << "<td>";
		if (R.Stats.Length and !R.Stats.Type) {
			auto N = FullScreenHTML(V);
			HTMLImgSub(ofs, V, N);
		}

		ofs << R.Name();
		if (!R.Owner->IsRetro()) {
			int W = R.Stats.WorstIndex - 1;
			int F = R.Stats.FailedIndexes;
			ofs << ((F) ? " ❌" : "");
			for_ (5) {
				if (i == W)  ofs << "<b>";
				ofs << "<br/>" + ScoreNames[i].substr(0,5) + " ";
				ofs.Oof() << std::fixed << std::setprecision(3) << R[i];
				ofs << (((1<<i) & F) ? " ❌" : "");
				if (i == W)  ofs << "</b>";
			}
			ofs << "<br/>";
		}
		
		ofs << "</td>\n";
	}


	void HTMLOpen(ArchiveFileOofer fs, string RealTitle) {
		fs << R"(<html>
<head>
	<title>)";
	fs << RealTitle;
	fs << R"(</title>
	<style>
body {
	background: black;
	color: white;
}
img {
	border-radius: 4.16666%;
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
	height: 64px;
	width:	64px;
	transition: 0.25s;
}


.full img {
	object-fit: contain;
	image-rendering: pixelated;
	height:	100%;
	width:	100%;
	filter: blur(calc(min(100vw,100vh)*0.004));
}
.full .img_ontop {
	object-fit: contain;
	position: relative;
	height:	calc(min(100vw,100vh));
	width:	calc(min(100vw,100vh));
}
.full .histo {
	object-fit: contain;
	height:	25%;
	width:	25%;
	filter: none;
}

	</style>
</head>
<body>
<table>
<tr>
)";
	}


	void HTMLClose(ArchiveFileOofer fs) {
		fs << R"(
</tr>
</table>
</body>
</html>)";
		fs.Close();
	}
	
	void Start() {
		if (Started) return; Started = true;
		
		ofs = B->Arc->AddFile(FileName, true).Oof();
	
		HTMLOpen(ofs, Title);
		cstring Row = "</tr>\n\n<tr><td><br/></td></tr><tr><td>\n"; 
		auto t = std::time(nullptr);
		auto tm = *std::localtime(&t);
		
		ofs << "<p>Created on: ";
		
		ofs.Oof() << std::put_time(&tm, "%d %b %y, %H:%M:%S"); 
		if (FileName == "scoring.html" or FileName == "temporal.html")
			ofs << "<br/>&nbsp;&nbsp;<a href='scoring.html'>Scoring</a>&nbsp;&nbsp;<a href='temporal.html'>Temporal</a>";
		ofs << "&nbsp;&nbsp;<a href='http://github.com/gamblevore/temporal'>github</a>";
		ofs << "</p>";
		ofs << Row;

		HTMLImg(B->MinMaxes[0].get());
		HTMLImg(B->MinMaxes[1].get());
		HTMLImg(B->MinMaxes[2].get());
		ofs << Row;
	}


	string FullScreenHTML(GenApproach* V) {
		GenApproach& R = *V;
		auto fs = R.Arc("_view.html").Oof();
		HTMLOpen(fs, "🔎 " + R.Name() + " 🔎");
		fs << "<div class='full'>";
		HTMLImgSub(fs, V, "");
		fs << "</div>";
		HTMLClose(fs);
		return fs.Path();
	}
	
	
	void HTMLImgSub(ArchiveFileOofer fs, GenApproach* V, string Link) {
		GenApproach& R = *V;
		fs << "<div class='img_ontop'>\n";
		if (Link!="")
			fs << "<a href='"+Link+"' target='_'>";
		fs << "<img class='behind'  src='" + R.FileName()    + "' />\n";
		if (!R.IsExternal())
			fs << "<img class='main' src='"+ R.FileName("p") + "' />";
		if (Link!="") {
			fs << "</a>";
			fs << "<img class='histo' src='"   + R.FileName("h") + "' />\n";
		}
		fs << "</div><br/>\n";
	}


	void WriteOne(GenApproach* App) {
		if (!Started) return;
		cstring Row = "</tr>\n\n<tr><td><br/></td></tr><tr>\n";
		if (!App->Stats.Length) return;
		if (Variations % 8 == 0) ofs << Row;
		HTMLImg(App);
		Variations++;
	}
	

	void Finish() {
		if (!Started) return;
		printf("\n:: %i Randomness variations!  :: \n", Variations);
		
		HTMLClose(ofs);
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


void BookHitter::CreateDirs(string path) {
	if (CreatedDirs or !LogOrDebug()) return;

	CreatedDirs = true;
	if (path == "") {
		if (fexists("/tmp/")) {
			path = "/tmp/temporal_scoring/";
		} else {
			path = GetCWD();
		}
	}
	Arc->Init(path);
}


void BookHitter::TryLogApproach(string Debiased="") {
	if (!LogOrDebug() or NoImgs()) return;
	int N = App->Stats.Length;
	u8* R = Extracted();
	if (Debiased != "")
		WriteColorImg(R, N, App->Png(Debiased));
	  else
		WriteColorImg(R, N, App->Png());
}
