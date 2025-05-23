void CMD_Setup()
{
	RegAdminCmd("sm_refresh_vips", ReloadVIPPlayers_CMD, ADMFLAG_ROOT);
	RegAdminCmd("sm_reload_vip_cfg", ReloadVIPCfg_CMD, ADMFLAG_ROOT);
	RegAdminCmd("sm_addvip", AddVIP_CMD, ADMFLAG_ROOT);
	RegAdminCmd("sm_setvip", SetVIP_CMD, ADMFLAG_ROOT);
	RegAdminCmd("sm_delvip", DelVIP_CMD, ADMFLAG_ROOT);

	#if USE_ADMINMENU
	RegAdminCmd("sm_vipadmin", VIPAdmin_CMD, ADMFLAG_ROOT);
	#endif

	#if DEBUG_MODE
	RegAdminCmd("sm_vip_dump_features", DumpFeatures_CMD, ADMFLAG_ROOT);
	#endif
}

public void OnConfigsExecuted()
{
	static bool bIsRegistered;
	if (bIsRegistered == false)
	{
		UTIL_LoadVipCmd(g_CVAR_hVIPMenu_CMD, VIPMenu_CMD);

		bIsRegistered = true;
	}
}

#if USE_ADMINMENU
public Action VIPAdmin_CMD(int iClient, int iArgs)
{
	if (iClient)
	{
		DisplayAdminMenu(iClient);
	}
	
	return Plugin_Handled;
}
#endif

public Action ReloadVIPPlayers_CMD(int iClient, int iArgs)
{
	UTIL_ReloadVIPPlayers(iClient, true);
	
	return Plugin_Handled;
}

public Action ReloadVIPCfg_CMD(int iClient, int iArgs)
{
	ReadConfigs();
	UTIL_ReloadVIPPlayers(iClient, false);
	UTIL_Reply(iClient, "%t", "VIP_CFG_REFRESHED");
	
	return Plugin_Handled;
}

public Action AddVIP_CMD(int iClient, int iArgs)
{
	if (iArgs != 3)
	{
		ReplyToCommand(iClient, "[VIP] %t!\nSyntax: sm_addvip <#steam_id|#name|#userid> <group> <time>", "INCORRECT_USAGE");
		return Plugin_Handled;
	}
	
	char szBuffer[64], szTargetName[MAX_TARGET_LENGTH];
	GetCmdArg(1, SZF(szBuffer));

	int[] iTargetList = new int[MaxClients];
	bool bIsMulti;
	int iTargets, iAccountID = 0;

	if((iTargets = ProcessTargetString(
			szBuffer,
			iClient, 
			iTargetList, 
			MaxClients, 
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
			SZF(szTargetName),
			bIsMulti)) < 1)
	{
		iAccountID = UTIL_GetAccountIDFromSteamID(szBuffer);
		if(!iAccountID)
		{
			ReplyToTargetError(iClient, iTargets);
			return Plugin_Handled;
		}
	}

	char szGroup[64];
	GetCmdArg(3, SZF(szGroup));
	int iTime = StringToInt(szGroup);
	if (iTime < 0)
	{
		ReplyToCommand(iClient, "[VIP] %t", "INCORRECT_TIME");
		return Plugin_Handled;
	}

	szGroup[0] = 0;
	GetCmdArg(2, SZF(szGroup));
	if (!szGroup[0] || !UTIL_CheckValidVIPGroup(szGroup))
	{
		ReplyToCommand(iClient, "%t", "VIP_GROUP_DOES_NOT_EXIST");
		return Plugin_Handled;
	}

	if(iTargets > 0)
	{
		for(int i = 0; i < iTargets; ++i)
		{
			if(IsClientInGame(iTargetList[i]))
			{
				UTIL_ADD_VIP_PLAYER(iClient, iTargetList[i], _, UTIL_TimeToSeconds(iTime), szGroup);
			}
		}
	
		return Plugin_Handled;
	}
	
	UTIL_ADD_VIP_PLAYER(iClient, _, iAccountID, UTIL_TimeToSeconds(iTime), szGroup);

	return Plugin_Handled;
}

public Action SetVIP_CMD(int iClient, int iArgs)
{
	if (iArgs != 3)
	{
		ReplyToCommand(iClient, "[VIP] %t!\nSyntax: sm_setvip <#steam_id|#name|#userid> <group> <time>", "INCORRECT_USAGE");
		return Plugin_Handled;
	}
	
	char szBuffer[64], szTargetName[MAX_TARGET_LENGTH];
	GetCmdArg(1, SZF(szBuffer));

	int[] iTargetList = new int[MaxClients];
	bool bIsMulti;
	int iTargets, iAccountID = 0;

	if((iTargets = ProcessTargetString(
			szBuffer,
			iClient, 
			iTargetList, 
			MaxClients, 
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
			SZF(szTargetName),
			bIsMulti)) < 1)
	{
		iAccountID = UTIL_GetAccountIDFromSteamID(szBuffer);
		if(!iAccountID)
		{
			ReplyToTargetError(iClient, iTargets);
			return Plugin_Handled;
		}
	}

	char szGroup[64];
	GetCmdArg(3, SZF(szGroup));
	int iTime = StringToInt(szGroup);
	if (iTime < 0)
	{
		ReplyToCommand(iClient, "[VIP] %t", "INCORRECT_TIME");
		return Plugin_Handled;
	}

	szGroup[0] = 0;
	GetCmdArg(2, SZF(szGroup));
	if (!szGroup[0] || !UTIL_CheckValidVIPGroup(szGroup))
	{
		ReplyToCommand(iClient, "%t", "VIP_GROUP_DOES_NOT_EXIST");
		return Plugin_Handled;
	}

	if(iTargets > 0)
	{
		for(int i = 0; i < iTargets; ++i)
		{
			if(IsClientInGame(iTargetList[i]))
			{
				UTIL_SET_VIP_PLAYER(iClient, iTargetList[i], _, UTIL_TimeToSeconds(iTime), szGroup);
			}
		}

		return Plugin_Handled;
	}
	
	UTIL_SET_VIP_PLAYER(iClient, _, iAccountID, UTIL_TimeToSeconds(iTime), szGroup);

	return Plugin_Handled;
}

public Action DelVIP_CMD(int iClient, int iArgs)
{
	if (iArgs != 1)
	{
		ReplyToCommand(iClient, "%t!\nSyntax: sm_delvip <identity>", "INCORRECT_USAGE");
		return Plugin_Handled;
	}
	
	char szQuery[512], szAuth[MAX_NAME_LENGTH];
	GetCmdArg(1, SZF(szAuth));
	
	int iAccountID = UTIL_GetAccountIDFromSteamID(szAuth);
	if(!iAccountID)
	{
		ReplyToTargetError(iClient, COMMAND_TARGET_NONE);
		return Plugin_Handled;
	}

	FormatEx(SZF(szQuery), "SELECT `account_id`, `name`, `group` \
									FROM `vip_users` \
									WHERE `account_id` = %d%s LIMIT 1;", iAccountID, g_szSID);

	DebugMessage(szQuery);
	if (iClient)
	{
		iClient = UID(iClient);
	}

	DBG_SQL_Query(szQuery);
	g_hDatabase.Query(SQL_Callback_OnSelectRemoveClient, szQuery, iClient);

	return Plugin_Handled;
}

public void SQL_Callback_OnSelectRemoveClient(Database hOwner, DBResultSet hResult, const char[] szError, any iClient)
{
	DBG_SQL_Response("SQL_Callback_OnSelectRemoveClient");

	if (hResult == null || szError[0])
	{
		LogError("SQL_Callback_OnSelectRemoveClient: %s", szError);
	}
	
	if (iClient)
	{
		iClient = CID(iClient);
	}
	
	if (hResult.FetchRow())
	{
		DBG_SQL_Response("hResult.FetchRow()");
		int iAccountID = hResult.FetchInt(0);
		DBG_SQL_Response("hResult.FetchInt(0) = %d", iAccountID);
		char szName[MNL], szGroup[64];
		hResult.FetchString(1, SZF(szName));
		hResult.FetchString(2, SZF(szGroup));
		DBG_SQL_Response("hResult.FetchString(1) = '%s", szName);
		DB_RemoveClientFromID(iClient, _, iAccountID, true, szName, szGroup);
	}
	else
	{
		ReplyToCommand(iClient, "%t", "FIND_THE_ID_FAIL");
	}
}

#if DEBUG_MODE
public Action DumpFeatures_CMD(int iClient, int iArgs)
{
	int iFeatures = g_hFeaturesArray.Length;
	if(iFeatures != 0)
	{
		char szBuffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, SZF(szBuffer), "data/vip/features_dump.txt");
		File hFile = OpenFile(szBuffer, "w");

		if(hFile != null)
		{
			char szPluginName[64];
			char szPluginPath[PLATFORM_MAX_PATH];
			char szPluginVersion[32];
			char szFeature[FEATURE_NAME_LENGTH];
			char szFeatureType[32];
			char szFeatureValType[32];
			ArrayList hArray;
			Handle hPlugin;

			for(int i = 0; i < iFeatures; ++i)
			{
				g_hFeaturesArray.GetString(i, SZF(szFeature));
				if(GLOBAL_TRIE.GetValue(szFeature, hArray))
				{
					hPlugin = view_as<Handle>(hArray.Get(FEATURES_PLUGIN));
					GetPluginInfo(hPlugin, PlInfo_Name, SZF(szPluginName));
					GetPluginInfo(hPlugin, PlInfo_Version, SZF(szPluginVersion));
					GetPluginFilename(hPlugin, SZF(szPluginPath));
					
					strcopy(SZF(szFeatureType), g_szFeatureType[view_as<int>(hArray.Get(FEATURES_ITEM_TYPE))]);
					strcopy(SZF(szFeatureValType), g_szValueType[view_as<int>(hArray.Get(FEATURES_VALUE_TYPE))]);
					
					hFile.WriteLine("%d. %-32s %-16s %-16s %-64s %-32s %-256s", i, szFeature, szFeatureType, szFeatureValType, szPluginName, szPluginVersion, szPluginPath);
				}
			}
		}

		delete hFile;
	}
	
	return Plugin_Handled;
}
#endif

public Action VIPMenu_CMD(int iClient, int iArgs)
{
	if (iClient)
	{
		if (OnVipMenuFlood(iClient) == false)
		{
			if (g_iClientInfo[iClient] & IS_VIP)
			{
				g_hVIPMenu.Display(iClient, MENU_TIME_FOREVER);
			}
			else
			{
				/*
				PrintToChat(iClient, "%t%t", "VIP_CHAT_PREFIX", "COMMAND_NO_ACCESS");
				*/
				
				PlaySound(iClient, NO_ACCESS_SOUND);
				DisplayClientInfo(iClient, "no_access_info");
			}
		}
	}
	return Plugin_Handled;
}