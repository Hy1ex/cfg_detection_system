#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientmod>
#include <multicolors>

#define PLUGIN_VERSION "1.3.0"

enum struct ConVarCheck {
    char name[64];
    char oldclientValue[32];
    char clientmodValue[32];
    int valueType; // 0 = exact, 1 = min, 2 = max
}

ConVarCheck g_ConVarChecks[] = {
    {"cl_minmodels", "0", "0", 0},
	{"cl_interpolate", "1.0", "1.0", 0},
	{"cl_interp_ratio", "2.0", "2.0", 0},
	{"cl_lagcompensation", "1", "1", 0},
	{"cl_pred_optimize", "2", "", 0},
	{"cl_predictweapons", "1", "1", 0},
	{"cl_resend", "6", "6", 0},
	{"cl_smooth", "1", "1", 0},
	{"cl_smoothtime", "0.1", "0.1", 0},
	{"cl_updaterate", "30", "30", 1},
	{"cl_updaterate", "100", "128", 2},
	{"cl_cmdrate", "30", "30", 1},
	{"cl_cmdrate", "100", "128", 2},
	{"cl_ejectbrass", "1", "1", 0},
	{"cl_pitchdown", "89", "89", 0},
	{"cl_pitchup", "89", "89", 0},
	{"cl_pitchspeed", "225", "225", 0},
	{"cl_yawspeed", "210", "210", 0},
	{"cl_wpn_sway_interp", "0.1", "0.1", 0},
	{"c_maxpitch", "90", "", 0},
	{"c_minpitch", "0", "", 0},
	{"c_maxyaw", "135", "", 0},
	{"c_minyaw", "-135", "", 0},
	{"c_maxdistance", "200", "", 0},
	{"c_mindistance", "30", "", 0},	
	{"cam_maxpitch", "", "90", 0},
	{"cam_minpitch", "", "0", 0},
	{"cam_maxyaw", "", "135", 0},
	{"cam_minyaw", "", "-135", 0},
	{"cam_maxdistance", "", "200", 0},
	{"cam_mindistance", "", "30", 0},
	{"r_drawothermodels", "1", "1", 0},
	{"r_drawstaticprops", "1", "1", 0},
	{"r_rootlod", "0", "0", 0},
	{"r_lod", "-1", "-1", 0},
	{"r_staticprop_lod", "", "-1", 0},
	{"r_drawmodeldecals", "1", "1", 0},
	{"r_renderoverlayfragment", "1", "1", 0},
	{"m_yaw", "0.022", "0.022", 0},
	{"m_pitch", "0.022", "0.022000", 0},
	{"m_side", "0.8", "0.8", 0},
	{"m_forward", "1", "1", 0},
	{"mat_clipz", "1", "1", 0},
	{"mat_dxlevel", "90", "90", 1},
	{"snd_mixahead", "0.1", "0.1", 0},
	{"sv_cheats", "0", "0", 0},
	{"scr_centertime", "2", "2", 0},
	{"net_maxfragments", "1280", "1280", 0},
	{"blink_duration", "0.2", "0.2", 0},
	{"showhitlocation", "0", "0", 0},
	{"fog_enable", "1", "1", 0},
	{"datacachesize", "32", "", 0},
	{"dsp_slow_cpu", "0", "0", 0}
};

// ConVar Handles
ConVar g_cvAdminFlag;
ConVar g_cvAutoDetect;
ConVar g_cvPunishMode;
ConVar g_cvBanMode;
ConVar g_cvBanDuration;

// Player state arrays
bool g_bIsClientMod[MAXPLAYERS+1];
bool g_bChecking[MAXPLAYERS+1];
ArrayList g_hCheckQueue[MAXPLAYERS+1];
int g_iCurrentCheck[MAXPLAYERS+1];
ArrayList g_hViolations[MAXPLAYERS+1]; // Stores all violations per client
int g_iInitiator[MAXPLAYERS+1];

public Plugin myinfo = 
{
    name = "ConVar Checker",
    author = "hy1ex",
    description = "Checks client convar to ensure player is not using values that give them unfair advantage.",
    version = PLUGIN_VERSION,
    url = "https://github.com/Hy1ex"
};

public void OnPluginStart()
{
    // Create plugin convars
    g_cvAdminFlag = CreateConVar("sm_cvc_adminflag", "e", "Admin flag needed for ConVar Checker menu access");
    g_cvAutoDetect = CreateConVar("sm_cvc_autodetect", "0", "Automatically check players on join? 0=Off, 1=On", _, true, 0.0, true, 1.0);
    g_cvPunishMode = CreateConVar("sm_cvc_punishmode", "1", "Punishment mode: 0=Report, 1=Kick, 2=Ban", _, true, 0.0, true, 2.0);
    g_cvBanMode = CreateConVar("sm_cvc_ban_mode", "1", "Ban mode: 1=SteamID, 2=IP Address", _, true, 1.0, true, 2.0);
    g_cvBanDuration = CreateConVar("sm_cvc_ban_duration", "120", "Ban duration in minutes (0=permanent)");
    
    // Register commands
    RegConsoleCmd("sm_cfg", Command_ConvarChecker, "Opens ConVar Checker menu");
    RegConsoleCmd("sm_cvc", Command_ConvarChecker, "Opens ConVar Checker menu");
    RegConsoleCmd("sm_convarchecker", Command_ConvarChecker, "Opens ConVar Checker menu");
    
    // Add convar change hooks
    g_cvAutoDetect.AddChangeHook(ConVarChanged_AutoDetect);
    
    // Initialize player arrays
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            OnClientPutInServer(i);
        }
    }
    
    // Create config file
    AutoExecConfig(true, "convar_checker");
}

public void OnConfigsExecuted()
{
    // Check all players if auto-detection is enabled
    if (g_cvAutoDetect.BoolValue) {
        for (int client = 1; client <= MaxClients; client++) {
            if (IsClientInGame(client) && !IsFakeClient(client) && !g_bChecking[client]) {
                StartConVarCheck(client, 0);
            }
        }
    }
}

public void ConVarChanged_AutoDetect(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) == 1) {
        // Check all current players when auto-detection is enabled
        for (int client = 1; client <= MaxClients; client++) {
            if (IsClientInGame(client) && !IsFakeClient(client) && !g_bChecking[client]) {
                StartConVarCheck(client, 0);
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    g_bIsClientMod[client] = false;
    g_bChecking[client] = false;
    g_iCurrentCheck[client] = 0;
    g_iInitiator[client] = 0;
    delete g_hCheckQueue[client];
    delete g_hViolations[client];
    
    // Check if clientmod is already available
    char version[8];
    if (CM_GetClientModVersion(client, version, sizeof(version))) {
        g_bIsClientMod[client] = true;
    }
}

public void OnClientDisconnect(int client)
{
    g_bIsClientMod[client] = false;
    g_bChecking[client] = false;
    g_iCurrentCheck[client] = 0;
    g_iInitiator[client] = 0;
    delete g_hCheckQueue[client];
    delete g_hViolations[client];
}

public void CM_OnClientAuth(int client, CMAuthType type)
{
    char version[8];
    if (CM_GetClientModVersion(client, version, sizeof(version))) {
        g_bIsClientMod[client] = true;
    } else {
        g_bIsClientMod[client] = false;
    }
    
    // Auto check if enabled
    if (g_cvAutoDetect.BoolValue && IsClientInGame(client) && !IsFakeClient(client)) {
        CreateTimer(5.0, Timer_DelayedCheck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_DelayedCheck(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client)) {
        StartConVarCheck(client, 0);
    }
    return Plugin_Stop;
}

void StartConVarCheck(int client, int initiator)
{
    if (g_bChecking[client]) return;
    
    g_iInitiator[client] = initiator;
	
    // Create check queue
    g_hCheckQueue[client] = new ArrayList();
    g_hViolations[client] = new ArrayList(256); // Store violation strings
    
    for (int i = 0; i < sizeof(g_ConVarChecks); i++) {
        g_hCheckQueue[client].Push(i);
    }
    
    if (g_hCheckQueue[client].Length == 0) {
        delete g_hCheckQueue[client];
        delete g_hViolations[client];
        return;
    }
    
    g_bChecking[client] = true;
    g_iCurrentCheck[client] = 0;
    ProcessNextCheck(client);
}

void ProcessNextCheck(int client)
{
    if (!g_bChecking[client] || g_iCurrentCheck[client] >= g_hCheckQueue[client].Length) {
        // All checks completed - process results
        g_bChecking[client] = false;
        
        if (g_hViolations[client] != null && g_hViolations[client].Length > 0) {
            ReportAllViolations(client);
            ApplyPunishment(client);
        } else {
            // Player is clean - report to initiator
            ReportCleanPlayer(client);
        }
        
        delete g_hCheckQueue[client];
        delete g_hViolations[client];
        g_iInitiator[client] = 0; // Reset initiator
        return;
    }
    
    int checkIndex = g_hCheckQueue[client].Get(g_iCurrentCheck[client]);
    char cvarName[64];
    strcopy(cvarName, sizeof(cvarName), g_ConVarChecks[checkIndex].name);
    
    QueryClientConVar(client, cvarName, ConVarQueryFinished);
}

void ReportCleanPlayer(int client)
{
    int initiator = GetClientOfUserId(g_iInitiator[client]);
    
    // If check was initiated by an admin and they're still connected
    if (initiator > 0 && IsClientInGame(initiator)) {
        CPrintToChat(initiator, "[{green}ConVar Checker{default}] Player {blue}%N{default} is clean.", client);
    }
    // If auto-detected and admin is watching, don't report clean players to avoid spam
}

public void ConVarQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (!g_bChecking[client]) return;
    
    int checkIndex = g_hCheckQueue[client].Get(g_iCurrentCheck[client]);
    char expectedValue[32];
    bool isClientMod = g_bIsClientMod[client];
    
    // Get expected value based on client type
    strcopy(expectedValue, sizeof(expectedValue), 
        isClientMod ? g_ConVarChecks[checkIndex].clientmodValue : g_ConVarChecks[checkIndex].oldclientValue);
    
    // Skip check if expected value is empty
    if (StrEqual(expectedValue, "", false)) {
        // Move to next check
        g_iCurrentCheck[client]++;
        ProcessNextCheck(client);
        return;
    }
    
    // Check for violation
    bool violation = false;
    char violationMsg[256];
    
    if (result != ConVarQuery_Okay) {
        Format(violationMsg, sizeof(violationMsg), "ConVar %s: Could not query value", cvarName);
        violation = true;
    }
    else {
        switch (g_ConVarChecks[checkIndex].valueType) {
            case 0: { // Exact match
                if (!StrEqual(cvarValue, expectedValue, false)) {
                    Format(violationMsg, sizeof(violationMsg), "ConVar %s: Expected '%s', Got '%s'", 
                        cvarName, expectedValue, cvarValue);
                    violation = true;
                }
            }
            case 1: { // Minimum value
                int actualInt = StringToInt(cvarValue);
                int expectedInt = StringToInt(expectedValue);
                if (actualInt < expectedInt) {
                    Format(violationMsg, sizeof(violationMsg), "ConVar %s: Expected min '%s', Got '%s'", 
                        cvarName, expectedValue, cvarValue);
                    violation = true;
                }
            }
            case 2: { // Maximum value
                int actualInt = StringToInt(cvarValue);
                int expectedInt = StringToInt(expectedValue);
                if (actualInt > expectedInt) {
                    Format(violationMsg, sizeof(violationMsg), "ConVar %s: Expected max '%s', Got '%s'", 
                        cvarName, expectedValue, cvarValue);
                    violation = true;
                }
            }
        }
    }
    
    // Store violation if found
    if (violation) {
        g_hViolations[client].PushString(violationMsg);
    }
    
    // Move to next check
    g_iCurrentCheck[client]++;
    ProcessNextCheck(client);
}

void ReportAllViolations(int client)
{
    char clientName[MAX_NAME_LENGTH];
    GetClientName(client, clientName, sizeof(clientName));
    
    int userid = GetClientUserId(client);
    
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) {
        strcopy(steamid, sizeof(steamid), "BOT");
    }
    
    char ip[32];
    GetClientIP(client, ip, sizeof(ip));
    
    char clientType[32];
    Format(clientType, sizeof(clientType), g_bIsClientMod[client] ? "ClientMod" : "Original/Old Client");
    
    // Report to admins
    char flagString[2];
    g_cvAdminFlag.GetString(flagString, sizeof(flagString));
    int flagBits = ReadFlagString(flagString);
    
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "sm_cvc_admin", flagBits)) {
            CPrintToChat(i, "[{green}ConVar Checker{default}] Player {red}%N{default} violation detected!", client);
            
            PrintToConsole(i, "===== ConVar Checker Violation Report =====");
            PrintToConsole(i, "Player: %s", clientName);
            PrintToConsole(i, "UserID: %d", userid);
            PrintToConsole(i, "SteamID: %s", steamid);
            PrintToConsole(i, "IP: %s", ip);
            PrintToConsole(i, "Client Type: %s", clientType);
            PrintToConsole(i, "Violations Found: %d", g_hViolations[client].Length);
            PrintToConsole(i, "-----------------------------------");
            
            // Print all violations
            char violationMsg[256];
            for (int j = 0; j < g_hViolations[client].Length; j++) {
                g_hViolations[client].GetString(j, violationMsg, sizeof(violationMsg));
                PrintToConsole(i, "%s", violationMsg);
            }
            
            PrintToConsole(i, "===========================================");
        }
    }
}

void ApplyPunishment(int client)
{
    int punishMode = g_cvPunishMode.IntValue;
    
    switch (punishMode) {
        case 1: // Kick
        {
            KickClient(client, "[ConVar Checker] Violation Detected, Please use default values.");
        }
        case 2: // Ban
        {
            int banMode = g_cvBanMode.IntValue;
            int duration = g_cvBanDuration.IntValue;
			
            int flags;
            switch (banMode)
            {
            case 1:
            {
                flags = BANFLAG_AUTHID;
            }
            case 2:
            {
                flags = BANFLAG_IP;
            }
            }
            
            char reason[256];
            Format(reason, sizeof(reason), "[ConVar Checker] Violation Detected.");
            
            char kickMsg[256];
            if (duration > 0) {
                Format(kickMsg, sizeof(kickMsg), "Banned for %d minutes. Reason: %s", duration, reason);
            } else {
                Format(kickMsg, sizeof(kickMsg), "Permanently banned. Reason: %s", reason);
            }
            
            BanClient(client, duration, flags, reason, kickMsg);
        }
    }
}

public Action Command_ConvarChecker(int client, int args)
{
    if (client == 0) {
        ReplyToCommand(client, "This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    // Check admin access
    char flagString[2];
    g_cvAdminFlag.GetString(flagString, sizeof(flagString));
    int flagBits = ReadFlagString(flagString);
    
    if (!CheckCommandAccess(client, "sm_cvc_admin", flagBits)) {
        ReplyToCommand(client, "You do not have access to this command.");
        return Plugin_Handled;
    }
    
    ShowPlayerMenu(client);
    return Plugin_Handled;
}

void ShowPlayerMenu(int client)
{
    Menu menu = new Menu(MenuHandler_PlayerSelect);
    menu.SetTitle("CFG Detector");
    
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            char name[MAX_NAME_LENGTH], info[8];
            GetClientName(i, name, sizeof(name));
            IntToString(i, info, sizeof(info));
            menu.AddItem(info, name);
        }
    }
    
    if (menu.ItemCount == 0) {
        menu.AddItem("", "No players available", ITEMDRAW_DISABLED);
    }
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerSelect(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select) {
        char info[8];
        menu.GetItem(param2, info, sizeof(info));
        int target = StringToInt(info);
        
        if (IsClientInGame(target)) {
            if (g_bChecking[target]) {
                CPrintToChat(param1, "[{green}ConVar Checker{default}] Player is currently being checked, Please wait.");
            } else {
                StartConVarCheck(target, GetClientUserId(param1));
                CPrintToChat(param1, "[{green}ConVar Checker{default}] Checking player {olive}%N{default}...", target);
            }
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}