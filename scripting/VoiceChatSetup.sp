#pragma semicolon 1
#pragma newdecls required
#include sdktools_gamerules

Handle  sv_deadtalk, sv_talk_after_dying_time;
Handle g_hTimer[MAXPLAYERS+1];
static int g_iTimer[MAXPLAYERS+1], g_isv_talk_after_dying_time;
static char sBuffer[256];
static bool g_bRoundEnd;

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

    sv_talk_after_dying_time = FindConVar("sv_talk_after_dying_time");
    g_isv_talk_after_dying_time = GetConVarInt(sv_talk_after_dying_time);
    CloseHandle(sv_talk_after_dying_time);

    sv_deadtalk = FindConVar("sv_deadtalk");
    int iFlags = GetConVarFlags(sv_deadtalk);
	iFlags &= ~FCVAR_NOTIFY;
	SetConVarFlags(sv_deadtalk, iFlags);

    HookConVarChange(sv_deadtalk, OnDeadTalkChange);

    LoadTranslations("VoiceChatSetup.phrases");
}

public void OnDeadTalkChange(Handle ConVars, const char[] oldValue, const char[] newValue)
{
    if(GetConVarInt(ConVars) == 1)
    {
        g_bRoundEnd = true;
        if(!KillAllTimers())
            PrintToServer("[DEBUG][VCS]: KillTimer ERROR!");
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
            {
                SetGlobalTransTarget(i);
                FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TO_ALL");
                PrintCenterText(i, sBuffer);
            }
        }
    }
    else
        g_bRoundEnd = false;
}

public void OnPluginEnd()
{
    int iFlags = GetConVarFlags(sv_deadtalk);
	iFlags |= ~FCVAR_NOTIFY;
	SetConVarFlags(sv_deadtalk, iFlags);
}

public void OnMapEnd()
{
    if(!KillAllTimers())
        PrintToServer("[DEBUG][VCS]: KillTimer ERROR!");
}

public void OnClientDisconnect(int iClient)
{
    g_iTimer[iClient] = g_isv_talk_after_dying_time;
    
    if(g_hTimer[iClient])
    {
        KillTimer(g_hTimer[iClient]);
        g_hTimer[iClient] = null;
    }
}

public void eRound_End(Event event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(sv_deadtalk, 1);
    //VoiceToAll();
}

public void eRound_Start(Event event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(sv_deadtalk, 0);
}

public void ePlayer_Death(Event event, const char[] name, bool dontBroadcast)
{
    if(GameRules_GetProp("m_bWarmupPeriod") || g_bRoundEnd)
        return;
    int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
    static int tt = 0, ct = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            switch (GetClientTeam(i))
            {
                case 2: tt++;
                case 3: ct++;
            }
        }
    }

    if(tt > 0 && ct > 0)
    {
        if(g_hTimer[iClient])
        {
            KillTimer(g_hTimer[iClient]);
            g_hTimer[iClient] = null;
        }

        g_hTimer[iClient] = CreateTimer(1.0, Timer_Delay, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    else
        SetConVarInt(sv_deadtalk, 1);
}

public Action Timer_Delay(Handle hTimer, int iClient)
{
    if(g_iTimer[iClient] > 0)
    {
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TIMER", g_iTimer[iClient]);
        PrintCenterText(iClient, sBuffer);
        g_iTimer[iClient]--;
    }
    else
    {
        SetGlobalTransTarget(iClient);
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TO_DIE");
        PrintCenterText(iClient, sBuffer);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}
/*
void VoiceToAll()
{
    if(!KillAllTimers())
        PrintToServer("[DEBUG][VCS]: KillTimer ERROR!");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
        {
            SetGlobalTransTarget(i);
            FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TO_ALL");
            PrintCenterText(i, sBuffer);
        }
    }
}
*/
bool KillAllTimers()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        g_iTimer[i] = g_isv_talk_after_dying_time;
        if(g_hTimer[i])
        {
            KillTimer(g_hTimer[i]);
            g_hTimer[i] = null;
        }
    }
    return true;
}