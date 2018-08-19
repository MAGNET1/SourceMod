public GoPrint(int client, char[] msg, any ...)
{
	int len = strlen(msg) + 255;
	char[] formatted = new char[len];
	VFormat(formatted, len, msg, 3);
	
	for (int i = 0; i < 13;i++)
	{
		if (StrContains(formatted, ColorsName[i], false) != -1)
			ReplaceString(formatted, len, ColorsName[i], ColorsTag[i], false);
	}
	
	CPrintToChat(client, "%s %s", TAG, formatted);
}