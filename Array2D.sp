#pragma semicolon 1

#include <sourcemod>

methodmap Array2D < ArrayList 
{ 
    public Array2D() 
    { 
        return view_as<Array2D>(new ArrayList()); 
    } 
    
    public int GetSize()
    {
    	return this.Length;
    }
    
    public ArrayList GetArrayHandle(int x)
    {
    	return this.Get(x);    	
    }
    
    public int PushEntry(int amount=1, int size=1)
    {
    	for (int i = 0; i < amount; i++)	this.Push(new ArrayList(size));
    	return this.Length-1;
    }
    
    public int EntrySize(int x)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.Length;
    }
    
    public void ShiftUpEntry(int x)
    {
		this.ShiftUp(x);
    }
    
    public void EraseEntry(int x)
    {
		ArrayList tmp = this.Get(x);
		tmp.Clear();
		tmp.Erase(x);
    }
    
    public void SwapEntries(int x1, int x2)
    {
    	this.SwapAt(x1, x2);
    }
    
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
    
    public void Clear2D(int x)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.Clear();	
    }
    
    public ArrayList Clone2D(int x)
    {
		ArrayList tmp = this.Get(x);
		return tmp.Clone();
    }
    
    public void Resize2D(int x, int newsize)
    {
		ArrayList tmp = this.Get(x);
		tmp.Resize(newsize);
    }
    
    public int Push2D(int x, int value)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.Push(value);
    	return tmp.Length-1;
    }
    
    public int PushString2D(int x, char[] tab)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.PushString(tab);
    	return tmp.Length-1;	
    }
    
    public int PushArray2D(int x, const any[] values, int size=-1)
    {
    	ArrayList tmp = this.Get(x);
    	tmp.PushArray(values, size);
    	return tmp.Length-1;	
    }
    
    public any Get2D(int x, int y, int block=0, bool asChar=false)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.Get(y, block, asChar);
    }
    
    public int GetString2D(int x, int y, char[] buffer, int size=-1)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.GetString(y, buffer, size);
    }	
    
    public int GetArray2D(int x, int y, any[] buffer, int size=-1)
    {
    	ArrayList tmp = this.Get(x);
    	return tmp.GetArray(y, buffer, size);
    }
    
    public void Set2D(int x, int y, any value, int block=0, bool asChar=false)
    {
		ArrayList tmp = this.Get(x);
		tmp.Set(y, value, block, asChar);
    }
    
    public void SetString2D(int x, int y, const char[] value)
    {
		ArrayList tmp = this.Get(x);
		tmp.SetString(y, value);
    }
    
    public void SetArray2D(int x, int y, const any[] values, int size=-1)
    {
		ArrayList tmp = this.Get(x);
		tmp.SetArray(y, values, size);
    }
    
    public void ShiftUp2D(int x, int y)
    {
		ArrayList tmp = this.Get(x);
		tmp.ShiftUp(y);
    }
    
    public void Erase2D(int x, int y)
    {
		ArrayList tmp = this.Get(x);
		tmp.Erase(y);
    }
    
    public void SwapAt2D(int x, int y1, int y2)
    {
		ArrayList tmp = this.Get(x);
		tmp.SwapAt(y1, y2);
    }
    
    public int FindString2D(int x, const char[] item)
    {
		ArrayList tmp = this.Get(x);
		return tmp.FindString(item);
    }
    
    public int FindValue2D(int x, any item, int block=0)
    {
		ArrayList tmp = this.Get(x);
		return tmp.FindValue(item, block);
    }
}  

public Plugin myinfo =
{
    name = "Array2D",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "Allows to create dwo-dimensional dynamic arrays",
    version = "0.1",
    url = "http://go-code.pl/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_test", testo);
}

public Action testo(int client, int args)
{
	Array2D Base = new Array2D(); // creates new 2D array
	Base.PushEntry(5); // pushes 5 entries - 5xPushCell(ArrayList)
	for (int i = 0; i < Base.GetSize(); i++)
	{
		for (int j = 0; j < 5; j++)	Base.Push2D(i, i * j * 5); // pushes cell value in the table at the given coordiantes
	}
	for (int i = 0; i < Base.GetSize(); i++)
	{
		for (int j = 0; j < Base.EntrySize(i);j++) // gets size of one entry
			PrintToChat(client, "%d", Base.Get2D(i, j)); // retrieves informations stored under given coords
	}
	
	Base.ClearEntries(); // clears the whole table
	PrintToChat(client, "%d", Base.GetSize());
}