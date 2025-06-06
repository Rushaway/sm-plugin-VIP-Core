#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

static TopMenuObject g_eAdminMenuObject = INVALID_TOPMENUOBJECT;
static TopMenu g_hTopMenu;
static Menu g_hVIPAdminMenu;

stock const char DATA_KEY_MenuType[] = "MenuType";
stock const char DATA_KEY_MenuListType[] = "MenuListType";
stock const char DATA_KEY_ThrowMenuType[] = "ThrowMenuType";
stock const char DATA_KEY_TargetID[] = "TargetID";
stock const char DATA_KEY_TargetUID[] = "TargetUID";
stock const char DATA_KEY_TimeType[] = "TimeType";
stock const char DATA_KEY_Time[] = "Time";
stock const char DATA_KEY_Name[] = "Name";
stock const char DATA_KEY_Group[] = "Group";
stock const char DATA_KEY_Auth[] = "Auth";
stock const char DATA_KEY_Offset[] = "Offset";
stock const char DATA_KEY_Search[] = "Search";

static const char g_szAdminMenuLibrary[] = "adminmenu";

enum AdminMenuType
{
	TOP_ADMIN_MENU = 0, 
	ADMIN_MENU
}

enum TimeActionItem
{
	TIME_SET = 0, 
	TIME_ADD, 
	TIME_TAKE
}

enum AdminMenuItem
{
	MENU_TYPE_ADD = 0, 
	MENU_TYPE_EDIT,
	MENU_TYPE_ONLINE_LIST,
	MENU_TYPE_DB_LIST
}

void DisplayAdminMenu(int iClient)
{
	g_hVIPAdminMenu.Display(iClient, MENU_TIME_FOREVER);
}

void BackToAdminMenu(int iClient)
{
	AdminMenuType eThrowMenuType;
	g_hClientData[iClient].GetValue(DATA_KEY_ThrowMenuType, eThrowMenuType);
	switch (eThrowMenuType)
	{
		case TOP_ADMIN_MENU:	g_hTopMenu.Display(iClient, TopMenuPosition_LastCategory);
		case ADMIN_MENU:		g_hVIPAdminMenu.Display(iClient, MENU_TIME_FOREVER);
	}
}

void InitiateDataMap(int iClient)
{
	if (g_hClientData[iClient] == null)
	{
		g_hClientData[iClient] = new StringMap();
	}
	else
	{
		g_hClientData[iClient].Clear();
	}
}

int IsClientOnline(int ID)
{
	int iClientID;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && g_hFeatures[i] != null && g_hFeatures[i].GetValue(KEY_CID, iClientID) && iClientID == ID) return i;
	}
	return 0;
}

// ************************ ADMIN_MENU ************************
void AdminMenu_Setup()
{
	g_hVIPAdminMenu = new Menu(Handler_VIPAdminMenu, MenuAction_Display | MenuAction_Select | MenuAction_DisplayItem);

	g_hVIPAdminMenu.AddItem(NULL_STRING, "vip_add");
	g_hVIPAdminMenu.AddItem(NULL_STRING, "vip_list");
	g_hVIPAdminMenu.AddItem(NULL_STRING, "vip_reload_players");
	g_hVIPAdminMenu.AddItem(NULL_STRING, "vip_reload_settings");

	if(LibraryExists(g_szAdminMenuLibrary))
	{
		TopMenu hTopMenu = GetAdminTopMenu();
		if(hTopMenu != null)
		{
			OnAdminMenuReady(hTopMenu);
		}
	}
}

public int Handler_VIPAdminMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(SZF(szTitle), "%T:\n ", "VIP_ADMIN_MENU_TITLE", iClient);
			(view_as<Panel>(iItem)).SetTitle(szTitle);
		}
		case MenuAction_DisplayItem:
		{
			char szDisplay[128];
			
			switch (iItem)
			{
				case 0:	FormatEx(SZF(szDisplay), "%T", "MENU_ADD_VIP", iClient);
				case 1:	FormatEx(SZF(szDisplay), "%T", "MENU_LIST_VIP", iClient);
				case 2:	FormatEx(SZF(szDisplay), "%T", "ADMIN_MENU_RELOAD_VIP_PLAYES", iClient);
				case 3:	FormatEx(SZF(szDisplay), "%T", "ADMIN_MENU_RELOAD_VIP_CFG", iClient);
			}
			
			return RedrawMenuItem(szDisplay);
		}
		
		case MenuAction_Select:
		{
			switch (iItem)
			{
				case 0:
				{
					InitiateDataMap(iClient);
					g_hClientData[iClient].SetValue(DATA_KEY_MenuType, MENU_TYPE_ADD);
					g_hClientData[iClient].SetValue(DATA_KEY_ThrowMenuType, ADMIN_MENU);
					ShowAddVIPMenu(iClient);
				}
				case 1:
				{
					InitiateDataMap(iClient);
					g_hClientData[iClient].SetValue(DATA_KEY_ThrowMenuType, ADMIN_MENU);
					ShowVipPlayersListMenu(iClient);
				}
				case 2:
				{
					ReloadVIPPlayers_CMD(iClient, 0);
					
					g_hVIPAdminMenu.Display(iClient, MENU_TIME_FOREVER);
				}
				case 3:
				{
					ReloadVIPCfg_CMD(iClient, 0);
					
					g_hVIPAdminMenu.Display(iClient, MENU_TIME_FOREVER);
				}
			}
		}
	}
	
	return 0;
}

// ************************ TOP_ADMIN_MENU ************************
public void OnLibraryAdded(const char[] szLibraryName)
{
	if (strcmp(szLibraryName, g_szAdminMenuLibrary) == 0)
	{
		TopMenu hTopMenu = GetAdminTopMenu();
		if (hTopMenu != null)
		{
			OnAdminMenuReady(hTopMenu);
		}
	}
}

public void OnLibraryRemoved(const char[] szLibraryName)
{
	if (strcmp(szLibraryName, g_szAdminMenuLibrary) == 0)
	{
		g_hTopMenu = null;
		g_eAdminMenuObject = INVALID_TOPMENUOBJECT;
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if (g_hTopMenu == hTopMenu)
	{
		return;
	}

	g_hTopMenu = hTopMenu;

	AddItemsToTopMenu();
}

void AddItemsToTopMenu()
{
	if (g_eAdminMenuObject == INVALID_TOPMENUOBJECT)
	{
		g_eAdminMenuObject = g_hTopMenu.AddCategory("vip_admin", Handler_MenuAdmin, "sm_vipadmin", ADMFLAG_ROOT);
	}

	g_hTopMenu.AddItem("vip_add", Handler_MenuAdd, g_eAdminMenuObject, "sm_vipadmin", ADMFLAG_ROOT);
	g_hTopMenu.AddItem("vip_list", Handler_MenuList, g_eAdminMenuObject, "sm_vipadmin", ADMFLAG_ROOT);
	g_hTopMenu.AddItem("vip_reload_players", Handler_MenuReloadPlayers, g_eAdminMenuObject, "sm_vipadmin", ADMFLAG_ROOT);
	g_hTopMenu.AddItem("vip_reload_settings", Handler_MenuReloadSettings, g_eAdminMenuObject, "sm_vipadmin", ADMFLAG_ROOT);
}

public void Handler_MenuAdmin(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLen)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:	FormatEx(szBuffer, iMaxLen, "%T", "VIP_ADMIN_MENU_TITLE", iClient);
		case TopMenuAction_DisplayTitle:	FormatEx(szBuffer, iMaxLen, "%T:\n ", "VIP_ADMIN_MENU_TITLE", iClient);
	}
}

// ************************ ADD_VIP ************************
public void Handler_MenuAdd(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLen)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:	FormatEx(szBuffer, iMaxLen, "%T", "MENU_ADD_VIP", iClient);
		case TopMenuAction_SelectOption:
		{
			InitiateDataMap(iClient);
			g_hClientData[iClient].SetValue(DATA_KEY_MenuType, MENU_TYPE_ADD);
			g_hClientData[iClient].SetValue(DATA_KEY_ThrowMenuType, TOP_ADMIN_MENU);
			ShowAddVIPMenu(iClient);
		}
	}
}

// ************************ LIST_VIP ************************

public void Handler_MenuList(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLen)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:	FormatEx(szBuffer, iMaxLen, "%T", "MENU_LIST_VIP", iClient);
		case TopMenuAction_SelectOption:
		{
			InitiateDataMap(iClient);
			g_hClientData[iClient].SetValue(DATA_KEY_ThrowMenuType, TOP_ADMIN_MENU);
			ShowVipPlayersListMenu(iClient);
		}
	}
}

// ************************ RELOAD_VIP_PLAYES ************************
public void Handler_MenuReloadPlayers(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLen)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:	FormatEx(szBuffer, iMaxLen, "%T", "ADMIN_MENU_RELOAD_VIP_PLAYES", iClient);
		case TopMenuAction_SelectOption:
		{
			ReloadVIPPlayers_CMD(iClient, 0);
			RedisplayAdminMenu(g_hTopMenu, iClient);
		}
	}
}

// ************************ RELOAD_VIP_CFG ************************
public void Handler_MenuReloadSettings(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLen)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:	FormatEx(szBuffer, iMaxLen, "%T", "ADMIN_MENU_RELOAD_VIP_CFG", iClient);
		case TopMenuAction_SelectOption:
		{
			ReloadVIPCfg_CMD(iClient, 0);
			
			RedisplayAdminMenu(g_hTopMenu, iClient);
		}
	}
}

void ShowTimeMenu(int iClient)
{
	Menu hMenu = new Menu(MenuHandler_TimeMenu);

	TimeActionItem iMenuType;
	g_hClientData[iClient].GetValue(DATA_KEY_TimeType, iMenuType);

	switch (iMenuType)
	{
		case TIME_SET: 	hMenu.SetTitle("%T:\n ", "MENU_TIME_SET", iClient);
		case TIME_ADD:	hMenu.SetTitle("%T:\n ", "MENU_TIME_ADD", iClient);
		case TIME_TAKE:	hMenu.SetTitle("%T:\n ", "MENU_TIME_TAKE", iClient);
	}

	hMenu.ExitBackButton = true;

	KeyValues hKv = CreateConfig("data/vip/cfg/times.ini", "TIMES");
	
	if (hKv.GotoFirstSubKey())
	{
		char szBuffer[128], szTime[32], szClientLang[4], szServerLang[4];
		GetLanguageInfo(GetServerLanguage(), SZF(szServerLang));
		GetLanguageInfo(GetClientLanguage(iClient), SZF(szClientLang));
		
		do
		{
			hKv.GetSectionName(SZF(szTime));

			if (iMenuType != TIME_SET && szTime[0] == '0') continue;

			hKv.GetString(szClientLang, SZF(szBuffer));
			if (!szBuffer[0])
			{
				hKv.GetString(szServerLang, SZF(szBuffer));
			}
			if (!szBuffer[0])
			{
				strcopy(SZF(szBuffer), "LangError");
			}

			hMenu.AddItem(szTime, szBuffer);

		}
		while (hKv.GotoNextKey(false));
	}
	
	delete hKv;

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_TimeMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch (action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if (iItem == MenuCancel_ExitBack)
			{
				AdminMenuItem eMenuItem;
				g_hClientData[iClient].GetValue(DATA_KEY_MenuType, eMenuItem);

				switch (eMenuItem)
				{
					case MENU_TYPE_ADD: 	ShowAddVIPMenu(iClient);
					case MENU_TYPE_EDIT:	ShowEditTimeMenu(iClient);
				}
			}
		}
		case MenuAction_Select:
		{
			char szName[64];
			hMenu.GetItem(iItem, SZF(szName));
			int iTime, iTarget;
			AdminMenuItem eMenuItem;
			iTime = S2I(szName);
			g_hClientData[iClient].GetValue(DATA_KEY_MenuType, eMenuItem);
			
			if (eMenuItem == MENU_TYPE_ADD)
			{
				g_hClientData[iClient].GetValue(DATA_KEY_TargetUID, iTarget);
				if ((iTarget = GetClientOfUserId(iTarget)))
				{
					char szBuffer[64];
					hMenu.GetItem(iItem, SZF(szBuffer));
					g_hClientData[iClient].SetValue(DATA_KEY_Time, S2I(szBuffer));
					ShowGroupsMenu(iClient);
				}
				else
				{
					VIP_PrintToChatClient(iClient, "%t", "PLAYER_NO_LONGER_AVAILABLE");
					BackToAdminMenu(iClient);
				}
				return 0;
			}

			char szTime[64];
			int iExpires;
			g_hClientData[iClient].GetString(DATA_KEY_Name, SZF(szName));

			TimeActionItem eTimeActionItem;
			g_hClientData[iClient].GetValue(DATA_KEY_TimeType, eTimeActionItem);
			switch(eTimeActionItem)
			{
				case TIME_SET:
				{
					if (iTime == 0)
					{
						iExpires = 0;
					}
					else
					{
						iExpires = GetTime() + iTime;
					}

					FormatTime(SZF(szTime), "%d/%m/%Y - %H:%M", iExpires);
					VIP_PrintToChatClient(iClient, "%t", "ADMIN_SET_EXPIRATION", szName, szTime);
					
					if (g_CVAR_bLogsEnable)
					{
						LogToFile(g_szLogFile, "%T", "LOG_ADMIN_SET_EXPIRATION", LANG_SERVER, iClient, szName, szTime);
					}
				}
				case TIME_ADD:
				{
					g_hClientData[iClient].GetValue(DATA_KEY_Time, iExpires);
					if (iExpires <= 0)
					{
						VIP_PrintToChatClient(iClient, "%t", "UNABLE_TO_EXTENDED");
						ShowTimeMenu(iClient);
						return 0;
					}

					iExpires += iTime;

					UTIL_GetTimeFromStamp(SZF(szTime), iTime, iClient);
					VIP_PrintToChatClient(iClient, "%t", "ADMIN_EXTENDED", szName, szTime);

					if (g_CVAR_bLogsEnable)
					{
						LogToFile(g_szLogFile, "%T", "LOG_ADMIN_EXTENDED", LANG_SERVER, iClient, szName, szTime);
					}
				}
				case TIME_TAKE:
				{
					g_hClientData[iClient].GetValue(DATA_KEY_Time, iExpires);
					if (iExpires <= 0)
					{
						VIP_PrintToChatClient(iClient, "%t", "UNABLE_TO_REDUCE");
						ShowTimeMenu(iClient);
						return 0;
					}

					iExpires -= iTime;
					
					if (iExpires <= GetTime())
					{
						VIP_PrintToChatClient(iClient, "%t", "INCORRECT_TIME");
						ShowTimeMenu(iClient);
						return 0;
					}
					
					UTIL_GetTimeFromStamp(SZF(szTime), iTime, iClient);

					VIP_PrintToChatClient(iClient, "%t", "ADMIN_REDUCED", szName, szTime);
					
					if (g_CVAR_bLogsEnable)
					{
						LogToFile(g_szLogFile, "%T", "LOG_ADMIN_REDUCED", LANG_SERVER, iClient, szName, szTime);
					}
				}
			}

			g_hClientData[iClient].GetValue(DATA_KEY_TargetID, iTarget);
			g_hClientData[iClient].SetValue(DATA_KEY_Time, iExpires);

			char szQuery[512];
			FormatEx(SZF(szQuery), "UPDATE `vip_users` SET `expires` = '%d' WHERE `account_id` = '%d'%s;", iExpires, iTarget, g_szSID);
			DBG_SQL_Query(szQuery);
			g_hDatabase.Query(SQL_Callback_ChangeTime, szQuery, UID(iClient));

			ShowTargetInfoMenu(iClient);
		}
	}

	return 0;
}

void ShowGroupsMenu(int iClient, const char[] sTargetGroup = NULL_STRING)
{
	char szGroup[MAX_NAME_LENGTH];
	Menu hMenu = new Menu(MenuHandler_GroupsList);
	hMenu.SetTitle("%T:\n ", "GROUP", iClient);
	hMenu.ExitBackButton = true;
	szGroup[0] = 0;
	g_hGroups.Rewind();
	if (g_hGroups.GotoFirstSubKey())
	{
		do
		{
			if (g_hGroups.GetSectionName(SZF(szGroup)))
			{
				if(sTargetGroup[0] && !strcmp(sTargetGroup, szGroup))
				{
					Format(SZF(szGroup), "%s [X]", szGroup);
					hMenu.AddItem(szGroup, szGroup, ITEMDRAW_DISABLED);
					continue;
				}

				hMenu.AddItem(szGroup, szGroup);
			}
		} while (g_hGroups.GotoNextKey());
	}
	if (!szGroup[0])
	{
		FormatEx(SZF(szGroup), "%T", "NO_GROUPS_AVAILABLE", iClient);
		hMenu.AddItem(NULL_STRING, szGroup, ITEMDRAW_DISABLED);
	}

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_GroupsList(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch (action)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel:
		{
			if (iItem == MenuCancel_ExitBack)
			{
				AdminMenuItem eMenuItem;
				g_hClientData[iClient].GetValue(DATA_KEY_MenuType, eMenuItem);
				switch(eMenuItem)
				{
					case MENU_TYPE_ADD:
					{
						ShowTimeMenu(iClient);
					}
					case MENU_TYPE_EDIT:
					{
						ShowTargetInfoMenu(iClient);
					}
				}
			}
		}
		case MenuAction_Select:
		{
			char szGroup[64];
			hMenu.GetItem(iItem, SZF(szGroup));
			AdminMenuItem eMenuItem;
			g_hClientData[iClient].GetValue(DATA_KEY_MenuType, eMenuItem);
			switch(eMenuItem)
			{
				case MENU_TYPE_ADD:
				{
					int iTarget, iBuffer;
					g_hClientData[iClient].GetValue(DATA_KEY_TargetUID, iTarget);
					iTarget = CID(iTarget);
					if (iTarget)
					{
						g_hClientData[iClient].GetValue(DATA_KEY_Time, iBuffer);
						g_hClientData[iClient].Clear();
						UTIL_ADD_VIP_PLAYER(iClient, iTarget, _, iBuffer, szGroup);
					}
					else
					{
						VIP_PrintToChatClient(iClient, "%t", "Player no longer available");
					}

					BackToAdminMenu(iClient);
				}
				case MENU_TYPE_EDIT:
				{
					char szQuery[256], szName[MNL], szOldGroup[64];
					hMenu.GetItem(iItem, SZF(szGroup));
					int iTargetID;
					g_hClientData[iClient].GetValue(DATA_KEY_TargetID, iTargetID);
					g_hClientData[iClient].GetString(DATA_KEY_Name, SZF(szName));
					g_hClientData[iClient].GetString(DATA_KEY_Group, SZF(szOldGroup));

					FormatEx(SZF(szQuery), "UPDATE `vip_users` SET `group` = '%s' WHERE `account_id` = %d%s;", szGroup, iTargetID, g_szSID);

					DBG_SQL_Query(szQuery);
					g_hDatabase.Query(SQL_Callback_ErrorCheck, szQuery);

					int iTarget = 0;
					g_hClientData[iClient].GetValue(DATA_KEY_TargetUID, iTarget);
					iTarget = CID(iTarget);
					if (!iTarget)
					{
						iTarget = IsClientOnline(iTargetID);
					}

					if (iTarget)
					{
						ResetClient(iTarget);
						CreateForward_OnVIPClientRemoved(iTarget, "VIP-Group Changed", iClient);
						Clients_CheckVipAccess(iTarget, false);
					}
	
					VIP_PrintToChatClient(iClient, "%t", "ADMIN_SET_GROUP", szName, szGroup);
					if (g_CVAR_bLogsEnable)
					{
						char szAdmin[256], szAdminInfo[128];
						UTIL_GetClientInfo(iClient, SZF(szAdminInfo));
						FormatEx(SZF(szAdmin), "%T %s", "BY_ADMIN", LANG_SERVER, szAdminInfo);
						LogToFile(g_szLogFile, "%T", "LOG_CHANGE_GROUP", LANG_SERVER, szName, iTargetID, szOldGroup, szGroup, szAdmin);
					}

					ShowTargetInfo(iClient);
				}
			}
		}
	}

	return 0;
}

public void SQL_Callback_ChangeTime(Database hOwner, DBResultSet hResult, const char[] szError, any UserID)
{
	DBG_SQL_Response("SQL_Callback_ChangeTime")
	if (szError[0])
	{
		LogError("SQL_Callback_ChangeTime: %s", szError);
		return;
	}

	DBG_SQL_Response("hResult.AffectedRows = %d", hResult.AffectedRows)

	if (hResult.AffectedRows)
	{
		int iClient = CID(UserID);
		if (iClient)
		{
			int iTarget;
			g_hClientData[iClient].GetValue(DATA_KEY_TargetUID, iTarget);
			iTarget = CID(iTarget);
			if(!iTarget)
			{
				g_hClientData[iClient].GetValue(DATA_KEY_TargetID, iTarget);
				iTarget = IsClientOnline(iTarget);
			}

			if (iTarget)
			{
				Clients_CheckVipAccess(iTarget, true);
			}
		}
	}
}

void ReductionMenu(Menu &hMenu, int iNum)
{
	for (int i = 0; i < iNum; ++i)
	{
		hMenu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_NOTEXT);
	}
}

public Action OnClientSayCommand(int iClient, const char[] szCommand, const char[] szArgs)
{
	if(iClient > 0 && iClient <= MaxClients && szArgs[0])
	{
		if(g_iClientInfo[iClient] & IS_WAIT_CHAT_SEARCH)
		{
			if(g_iClientInfo[iClient] & IS_WAIT_CHAT_SEARCH)
			{
				ShowWaitSearchMenu(iClient, szArgs);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
