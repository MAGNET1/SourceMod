public void InitConVars()
{
	cvar_MaxMailboxCapacity = CreateConVar("mb_mailbox_max_capacity", "50", "Maximum capacity of each mailbox");
	cvar_MaxAmountOfMailboxes = CreateConVar("mb_mailbox_max_amount", "10", "Maximum number of active mailboxes on the server");
	
}

public void OnConfigsExecuted()
{
	MaxMailboxCapacity = cvar_MaxMailboxCapacity.IntValue;
	MaxAmountOfMailboxes = cvar_MaxAmountOfMailboxes.IntValue;
}