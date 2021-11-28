#pragma semicolon 1
#pragma newdecls required
#include <sdktools_gamerules>
#include <sdktools>

Handle  sv_deadtalk;
Handle g_hTimer[MAXPLAYERS+1];
static int g_iTimer[MAXPLAYERS+1];
static char sBuffer[256];

public Plugin myinfo = 
{
	name = "Voice Chat Setup",
	author = "PSIH :{",
	description = "Setup & Notifications for voice chat(Who hears whom, who speaks to whom)",
	version = "1.0.0",
	url = "https://github.com/0RaKlE19/VoiceChatSetup"
};

public void OnPluginStart()
{
    HookEvent("round_end", eRound_End);
    HookEvent("round_start", eRound_Start);
    HookEvent("player_death", ePlayer_Death);

    sv_deadtalk = FindConVar("sv_deadtalk");
    int iFlags = GetConVarFlags(sv_deadtalk);
	iFlags &= ~FCVAR_NOTIFY;
	SetConVarFlags(sv_deadtalk, iFlags);

    LoadTranslations("VoiceChatSetup.phrases");
}

public void OnMapStart()
{
  AddFileToDownloadsTable("sound/welcome/welcomeclubbudy.mp3");
  PrecacheSound("welcome/welcomeclubbudy.mp3");
}

public void OnClientPostAdminCheck(int iClient)
{
    if(IsClientInGame(iClient))
        EmitSoundToClient(iClient, "welcome/welcomeclubbudy.mp3", _, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.5);
}

public void OnPluginEnd()
{
    int iFlags = GetConVarFlags(sv_deadtalk);
	iFlags |= FCVAR_NOTIFY;
	SetConVarFlags(sv_deadtalk, iFlags);
}

public void OnClientDisconnect(int iClient)
{
    if(g_hTimer[iClient])
    {
        KillTimer(g_hTimer[iClient]);
        g_hTimer[iClient] = null;
    }
}

public void eRound_End(Event event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(sv_deadtalk, 1);
    KillAllTimers();
}

public void eRound_Start(Event event, const char[] name, bool dontBroadcast){SetConVarInt(sv_deadtalk, 0);}

public void ePlayer_Death(Event event, const char[] name, bool dontBroadcast)
{
    if(GameRules_GetProp("m_bWarmupPeriod") || GetConVarInt(sv_deadtalk) == 1)
        return;
    int iClient = GetClientOfUserId(GetEventInt(event, "userid"));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
        {
            if(g_hTimer[iClient])
            {
                KillTimer(g_hTimer[iClient]);
                g_hTimer[iClient] = null;
            }
            g_iTimer[iClient] = 5;
            if(IsClientInGame(iClient) && !IsFakeClient(iClient))
                g_hTimer[iClient] = CreateTimer(1.0, Timer_Delay, iClient, TIMER_REPEAT);
            return;
        }
    }
    SetConVarInt(sv_deadtalk, 1);
    KillAllTimers();
}

public Action Timer_Delay(Handle hTimer, int iClient)
{
    if(!IsClientInGame(iClient) || GetConVarInt(sv_deadtalk) == 1)
    {
        g_hTimer[iClient] = null;
        return Plugin_Stop;
    }

    if(g_iTimer[iClient] > 0)
    {
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TIMER", g_iTimer[iClient]);
        PrintCenterText(iClient, sBuffer);
        g_iTimer[iClient] = g_iTimer[iClient] - 1;
    }
    else
    {
        SetGlobalTransTarget(iClient);
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TO_DIE");
        PrintCenterText(iClient, sBuffer);
        g_hTimer[iClient] = null;
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

void KillAllTimers()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(g_hTimer[i])
            KillTimer(g_hTimer[i]);
        g_hTimer[i] = null;
        if (IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
        {
            SetGlobalTransTarget(i);
            FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TO_ALL");
            PrintCenterText(i, sBuffer);
        }
    }
}