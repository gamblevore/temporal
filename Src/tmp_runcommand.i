

#define OptionList(A) auto A_ = A; if (false)
#define Option(B) } else if (matchi(A_,B)) {
int bh_run_command (BookHitter* External,  const char** argv, bool Archive) {
	auto Args = ArgArray(argv);
	int Err = 0;

	if (Args.size()) {
		auto B = External ? External : SteveDefault();
		B->Arc->WriteToDisk = !Archive;

		errno = 0;
		OptionList(Args[0]) {
		  Option ("dump")
			Err = DumpAction(B, Args, false);
		  
		  Option ("hexdump")
			Err = DumpAction(B, Args, true);
			
		  Option ("list")
			Err = ListAction(B, Args);
		  
		  Option ("read")
			Err = ViewAction(B, Args, false);
			
		  Option ("view")
			Err = ViewAction(B, Args, true);
			
		  Option ("print")
			Err = PrintAction(B, Args);

		} else {
			fprintf(stderr, "Unrecognised action: '%s'\n", A_.c_str());
			Err = ArgError; 
		}
		
		B->SendBack(argv);
	} else {
		Err = ArgError;
	}

	if (Err == ArgError)
		printf(
"Usage: temporal dump     (0 to 127) (1KB to 1000MB) (file.bin)\n"
"       temporal hexdump  (0 to 127) (1KB to 1000MB) (file.txt)\n"
"       temporal list     (0 to 127)\n"
"       temporal read     (file.txt)\n"
"       temporal view     (/path/to/folder/)\n"
"       cat file.txt | temporal view -       # temporal can read from stdin.\n"
"\n"
"  About: http://randonauts.com/s/temporal \n");

	printf("\n");
	return Err;
}


void bh_extract_archive (const char* Data, const char* Path) {
	Archive::WriteAnyway(Data, Path);
}

const char* IPhoneExample() {
	const char* input[] = {"temporal", "list", "1", 0};
	bh_run_command(nullptr, input, true);
	const char* iPhoneOutput = input[0];
	puts(iPhoneOutput); // or some other way to send it back to the Mac.
	return iPhoneOutput;
}

void MacOSXExample(const char* iPhoneOutput) { // take the data we just puts() on the iPhone
	bh_extract_archive(iPhoneOutput, "~/Desktop/TemporalList1");
}

void DummyIPhoneTest() {
	// normally we run these two funcs on different devices
	// but we can run it on the same, to test that it works even.
	auto x = IPhoneExample();
	MacOSXExample(x);
}
