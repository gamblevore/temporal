
/*
	* no more than 1.5 hours a day
	* 15 mins session... if I can't complete, it wastes hte entire
		* Don't worry... can think while not coding!
	* save enthusiasm!
	
	todo:
		* Y-table... of struct, with start/end int values
			* So we know if our x is within the circle or not!
			* 0.5 if so, 0 if not. or whatever.
		* write the points into every cell that can read them...
			* as ints, not uint
			* makes cells self-contained
		* process entire cell as one :)

*/
 
 
 
 
 
 
// OK... so its just a cell-grid system
// like do a blur, but mostly almost everything is empty.

class BlurrContainer;
#define CellSize 32
struct Point2 {
	int X;
	int Y;
};


vector<int>				CircleOffsets; // avoid sqrt

struct ImageCell {
	float				Data[CellSize*CellSize];
	BlurrContainer*		Parent;
	vector<Point2>		Points;
	
	ImageCell(BlurrContainer* p) {
		Parent = p;
	}
	
	float VRead(int x, int y) {
		float result = 0;
		
		for(auto&P:Points) {
			auto& C = CircleOffsets[y-P.Y];
			if (C < x - P.X) {
				result += 1.0;
			}
		}
		return result;
	}
	
	void VirtualProcess(int v, float* Table) {
		// So basically, blurr each pixel
		// Each pixel takes into account, a bunch of other pixels, but weighted.
		int wx = v%CellSize;
		int wy = v/CellSize;
		int rx = wx - (CellSize/2);
		float Total = 0;
		for_(CellSize) {
			float F = VRead(rx+i, wy);
			Total += F*Table[i]; 
		}
		Data[v] = Total;
	}
};



class BlurrContainer {
	vector<ref(ImageCell)>	Cells;
	vector<float>			Blurr;
	int W;
	int H;
	
	BlurrContainer(int x, int y) {
		x /= CellSize;
		y /= CellSize;
		W = x;
		H = y;
		Cells.resize(x*y);
		BuildCircleOffsets();
	}
	
	void BuildCircleOffsets() {
		// so... what are we doing even?
		// well... we are going along a grid.
		// And we have a circle somewhere distant.
		// we need to be a minimum distance from it.
		
		// OK so... an entire circle fits into one cell.
		// so it's radius is cellsize/2.
		// Well... technically, it's center is inbetween two cells then
		// no problem.
		
		// so... Assuming we measure from the top of the circle.
		// If we are aligned, we need to be directly above it (x=0)
		// in order to access it. (or perhaps x=-1 to 1)
		// So the height only needs to be cellsize.
		
		int Diameter = CellSize;
		CircleOffsets.resize(Diameter);
		// __o___________xx___
		// _____________xxxx__
		// ____________xxxxxx_
		// ____________xxxxxx_
		// _____________xxxx__
		// ______________xx___
		float Radius = ((float)Diameter)/2.0;
		for_(Diameter) {
			int y = Radius - i;
			int x = sqrt(y*y - Radius*Radius);
			CircleOffsets[i] = x;
		}
		// we wanna calculate... x, given y and r.
		// x^2 + y^2 = z^2
		// CircleOffsets[i] = sqrt(
	}
	
		
	ImageCell* GetCell (u32 x, u32 y, bool Create=false) {
		if (x<W and y<H) {
			int i = x + (y*W);
			auto C = Cells[i];
			if (!C) {
				if (!Create)
					return 0;
				C = New2(ImageCell, this);
				Cells[i] = C;
			}

			return C.get();
		}

		return 0;
	}
	
	void Process() {
		Blurrr();
		FindDarkest();
	}
	
	void FindDarkest() {
	}
	
	void Blurrr() {
		float* Table = &Blurr[0];
		for (auto C : Cells)
			for_(CellSize*CellSize)
				C->VirtualProcess(i, Table);
	}
};

