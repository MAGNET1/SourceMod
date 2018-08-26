public void PrecacheSounds()
{
	PrecacheSound("*/AchievementsGO/accomplished.mp3", true);
}

public void DownloadSounds()
{
	AddFileToDownloadsTable("sound/AchievementsGO/accomplished.mp3");
}

public void PlaySound_Accomplished(int client)
{
	EmitSoundToClient(client, "*/AchievementsGO/accomplished.mp3");
}
