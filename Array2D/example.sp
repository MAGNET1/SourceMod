#pragma semicolon 1

#include <sourcemod>
#include <Array2D>

public Plugin myinfo =
{
    name = "Array2D example",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "How to use",
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
		for (int j = 0; j < 5; j++)	Base.Push2D(i, i * j * 5); // pushes cell value to the table at the given coordinates
	}
	for (int i = 0; i < Base.GetSize(); i++)
	{
		for (int j = 0; j < Base.EntrySize(i);j++) // gets size of one entry
			PrintToChat(client, "%d", Base.Get2D(i, j)); // retrieves informations stored under given coords
	}
	
	Base.ClearEntries(); // clears the whole table
	PrintToChat(client, "%d", Base.GetSize());
}
