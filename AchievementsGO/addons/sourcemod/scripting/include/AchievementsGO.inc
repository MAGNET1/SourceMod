#if defined _AchievementsGO_included_
  #endinput
#endif
#define _AchievementsGO_included_
 
/**
 * Adds new achievement. This operation must be processed within AGO_OnRegisterAchievements()
 * function to make sure everything will load properly
 *
 * @param Name			Name of the achievement (up to 64 characters)
 * @param Description	Short description (up to 128 characters)
 * @param Category		Category of a certain Achievement. If you want it to be in the main section, leave blank ("")
 * @param Value			Sets the goal that achievement must meet to be accomplished
 * @return				ID of the achievement, -1 on failure or contains restricted characters.
 */
native int AGO_AddAchievement(char[] Name, char[] Description, char[] Category, int Value);

/**
 * Adds one point to the player's achievement
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @return					Current achievement progress or -1 if failure.
 */
native int AGO_AddPoint(int client, int IdOfAchievement);

/**
 * Adds points to the player's achievement
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @param amount			Amount of points to be given
 * @return					Current achievement progress or -1 if failure.
 */
native int AGO_AddPoints(int client, int IdOfAchievement, int amount);

/**
 * Removes one point of the player's achievement
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @return					Current achievement progress or -1 if failure.
 */
native int AGO_RemovePoint(int client, int IdOfAchievement);

/**
 * Removes points of the player's achievement
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @param amount			Amount of points to be taken away from
 * @return					Current achievement progress or -1 if failure.
 */
native int AGO_RemovePoints(int client, int IdOfAchievement, int amount);

/**
 * Sets the current progress of the achievement to 0
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @return					Current achievement progress or -1 if failure.
 */
native int AGO_ResetPoints(int client, int IdOfAchievement);

/**
 * Retrieves Achievement's name by its index
 *
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @param tab				Char[] array for Achievement's name
 * @param size				Size of the given array
 * @return					0 if success. On failure: -1 and array contains "NOT FOUND" string
 */
native void AGO_GetNameByIndex(int IdOfAchievement, char[] tab, int size);

/**
 * Retrieves Achievement's index, based on its name
 *
 * @param name				Array containing Achievement's name
 * @return					Achievement index if success. Otherwise, returns -1.
 */
native int AGO_GetIndexByName(char[] name);

/**
 * Retrieves Achievement's description by its index
 *
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @param tab				Char[] array for Achievement's description
 * @param size				Size of the given array
 * @return					0 if success. On failure: -1 and array contains "NOT FOUND" string
 */
native void AGO_GetDescriptionByIndex(int IdOfAchievement, char[] tab, int size);

/**
 * Retrieves current player Achievement's progress
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @return					Achievement's progress on success. Otherwise, returns -1.
 */
native int AGO_GetAchievementProgress(int client, int IdOfAchievement);

/**
 * Checks if a certain achievement has been completed
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 * @return					1: completed, 0: not completed, -1: failure
 */
native int AGO_IsAchievementCompleted(int client, int IdOfAchievement);

/**
 * Returns the current amount of active Achievements
 *
 * @return					Amount of active achievements
 */
native int AGO_GetAmountOfAchievements();

/**
 * Checks whether or not the SQL tables has been succesfully created.
 *
 * @return					1: Tables created, 0: tables not created
 */
native int AGO_AreTablesCreated();




/**
 * Called when all the achievements from all the plugins has been succesfully loaded
 */
forward void AGO_OnAllAchievementsLoaded();

/**
 * Called when a Achievement has been accomplished by a player
 *
 * @param client			ID of the client
 * @param IdOfAchievement	ID of achievement (retrieved from AGO_AddAchievement() function)
 */
forward void AGO_OnAchievementAccomplished(int client, int IdOfAchievement);

/**
 * Called when an engine is ready for registering new Achivements.That's the only place where it can be done
 */
forward void AGO_OnRegisterAchievements();