

#define OptionList(A) auto A_ = A; if (false)
#define Option(B) } else if (matchi(A_,B)) { Err = 

int bh_run_command (BookHitter* External, cstring* argv, bool Archive) {
	auto Args = ArgArray(argv);
	int Err = ArgError;

	if (Args.size()) {
		auto B = External ? External : SteveDefault();
		B->Arc->WriteToDisk = !Archive;

		OptionList(Args[0]) {
		  Option ("dump")		DumpAction		(B, Args, false);
		  Option ("hexdump")	DumpAction		(B, Args, true);
		  Option ("list")		ListAction		(B, Args);
		  Option ("read")		ViewAction		(B, Args, false);			
		  Option ("view")		ViewAction		(B, Args, true);
		  Option ("print") 		PrintAction		(B, Args);
		  Option ("unarchive")	UnarchiveAction (B, Args);
		  Option ("leaktest")   LeakTestAction  (B, Args);
		} else {
			fprintf(stderr, "Unrecognised action: '%s'\n", A_.c_str());
		}
		
		B->SendBack(argv);
	}

	if (Err == ArgError)
		printf(
"Usage: temporal dump       (0 to 127) (1KB to 1000MB) (file.bin)\n"
"       temporal hexdump    (0 to 127) (1KB to 1000MB) (file.txt)\n"
"       temporal list       (0 to 127)\n"
"       temporal read       (file.txt)\n"
"       temporal view       (/path/to/folder/)\n"
"       temporal unarchive  (/path/to/archive /path/output_dir/)\n"
"       cat file.txt | temporal view       # temporal can read from stdin.\n"
"\n"
);

	printf("\n");
	return Err;
}

void bh_extract_archive (cstring Data, cstring Path) {
	Archive::WriteAnyway(Data, Path);
}


cstring IPhoneExample() {
	cstring input[] = {"temporal", "list", "1", 0};
	bh_run_command(nullptr, input, true);
	cstring iPhoneOutput = input[0];
	puts(iPhoneOutput); // or some other way to send it back to the Mac.
	return iPhoneOutput;
}


void MacOSXExample(cstring iPhoneOutput) { // take the data we just puts() on the iPhone
	bh_extract_archive(iPhoneOutput, "~/Desktop/TemporalList1");
}


void DummyIPhoneTest() {
	// normally we run these two funcs on different devices
	// but we can run it on the same, to test that it works even.
	auto x = IPhoneExample();
	MacOSXExample(x);
}
