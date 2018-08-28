#if defined _Array2D_included_
  #endinput
#endif
#define _Array2D_included_
 

methodmap Array2D < ArrayList 
{ 
	// constructor
    public Array2D() 
    { 
        return view_as<Array2D>(new ArrayList()); 
    } 
    
    // gets number of entries
    public int GetSize()
    {
    	return this.Length;
    }
    
    // based on index, returns ArrayList handle that entry is attached to
    public ArrayList GetArrayHandle(int x)
    {
    	return this.Get(x);    	
    }
    
    // adds one or more new entries with given size (works just like CreateArray(size))
    public int PushEntry(int amount=1, int size=1)
    {
    	for (int i = 0; i < amount; i++)	this.Push(new ArrayList(size));
    	return this.Length-1;
    }
    
    // returns number of elements of a given entry
    public int EntrySize(int x)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.Length;
    }
    
    // shifts entries up and creates new entry in the blank space
    public void ShiftUpEntry(int x, size=1)
    {
		this.ShiftUp(x);
		this.Set(x, new ArrayList(size))
    }
    
    // Erases certain entry and shifts everything down
    public void EraseEntry(int x)
    {
		ArrayList tmp = this.Get(x);
		tmp.Clear();
		this.Erase(x);
    }
    
    // changes position of two entries
    public void SwapEntries(int x1, int x2)
    {
    	this.SwapAt(x1, x2);
    }
    
    // clears everything...
    public void ClearEntries()
    {
    	ArrayList tmp;
    	for (int i = 0; i < this.Length;i++)
    	{
		tmp = this.Get(i);
		tmp.Clear();
    	}
    	this.Clear();
    }
    
    // removes content of a given entry
    public void Clear2D(int x)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.Clear();	
    }
    
    // clones entry and returns new ArrayList Handle
    public ArrayList Clone2D(int x)
    {
		ArrayList tmp = this.Get(x);
		return tmp.Clone();
    }
    
    // changes size of entry
    public void Resize2D(int x, int newsize)
    {
		ArrayList tmp = this.Get(x);
		tmp.Resize(newsize);
    }
    
    // pushes new value to the entry
    public int Push2D(int x, int value)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.Push(value);
    	return tmp.Length-1;
    }
    
    // pushes string to the entry
    public int PushString2D(int x, char[] tab)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.PushString(tab);
    	return tmp.Length-1;	
    }
    
    // pushes array to the entry
    public int PushArray2D(int x, const any[] values, int size=-1)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.PushArray(values, size);
    	return tmp.Length-1;	
    }
    
    // returns cell from the given coordinates
    public any Get2D(int x, int y, int block=0, bool asChar=false)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.Get(y, block, asChar);
    }
    
    // returns string from the given coordinates
    public int GetString2D(int x, int y, char[] buffer, int size=-1)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.GetString(y, buffer, size);
    }	
    
    // returns array from the given coordinates
    public int GetArray2D(int x, int y, any[] buffer, int size=-1)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.GetArray(y, buffer, size);
    }
    
    // sets cell value under the given coordinates
    public void Set2D(int x, int y, any value, int block=0, bool asChar=false)
    {
		ArrayList tmp = this.Get(x);
		tmp.Set(y, value, block, asChar);
    }
    
    // sets string value under the given coordinates
    public void SetString2D(int x, int y, const char[] value)
    {
		ArrayList tmp = this.Get(x);
		tmp.SetString(y, value);
    }
    
    // sets array under the given coordinates
    public void SetArray2D(int x, int y, const any[] values, int size=-1)
    {
		ArrayList tmp = this.Get(x);
		tmp.SetArray(y, values, size);
    }
    
    // shifts content of entry up
    public void ShiftUp2D(int x, int y)
    {
		ArrayList tmp = this.Get(x);
		tmp.ShiftUp(y);
    }
    
    // erases block under given coordinates
    public void Erase2D(int x, int y)
    {
		ArrayList tmp = this.Get(x);
		tmp.Erase(y);
    }
    
    // swaps two blocks of a given entry
    public void SwapAt2D(int x, int y1, int y2)
    {
		ArrayList tmp = this.Get(x);
		tmp.SwapAt(y1, y2);
    }
    
    // finds string in the given entry
    public int FindString2D(int x, const char[] item)
    {
		ArrayList tmp = this.Get(x);
		return tmp.FindString(item);
    }
    
    // finds value in the given entry
    public int FindValue2D(int x, any item, int block=0)
    {
		ArrayList tmp = this.Get(x);
		return tmp.FindValue(item, block);
    }
}  
