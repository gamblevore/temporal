

#define OptionList(A) auto A_ = A; if (false)
#define Option(B) } else if (matchi(A_,B)) {
int bh_run_command (BookHitter* B_,  char** argv) {
	auto Args = ArgArray((const char**)argv);
	int Err = 0;

	if (Args.size()) {
		OrigPath = GetCWD();
		auto B = B_ ? B_ : bh_create();

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

		} else {
			fprintf(stderr, "Unrecognised action: '%s'\n", A_.c_str());
			Err = ArgError; 
		}

		bh_free(B_);
		chduuhh(OrigPath.c_str());
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

