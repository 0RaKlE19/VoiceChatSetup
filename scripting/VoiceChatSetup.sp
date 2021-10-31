#pragma semicolon 1
#pragma newdecls required

Handle  sv_deadtalk;
Handle g_hTimer[MAXPLAYERS+1];
static int g_iTimer[MAXPLAYERS+1], g_isv_talk_after_dying_time;
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

    sv_deadtalk = FindConVar("sv_talk_after_dying_time");
    g_isv_talk_after_dying_time = GetConVarInt(sv_deadtalk);

    sv_deadtalk = FindConVar("sv_deadtalk");
    int iFlags = GetConVarFlags(sv_deadtalk);
	iFlags &= ~FCVAR_NOTIFY;
	SetConVarFlags(sv_deadtalk, iFlags);

    LoadTranslations("VoiceChatSetup.phrases");
}

public void OnPluginEnd()
{
    UnhookEvent("round_end", eRound_End);
    UnhookEvent("player_death", ePlayer_Death);
    UnhookEvent("round_start", eRound_Start);

    int iFlags = GetConVarFlags(sv_deadtalk);
	iFlags |= ~FCVAR_NOTIFY;
	SetConVarFlags(sv_deadtalk, iFlags);
    CloseHandle(sv_deadtalk);
    KillAllTimers();
}

public void OnClientDisconnect(int iClient)    // Игрок отключился
{
    if(g_hTimer[iClient] != INVALID_HANDLE)    // Проверяем что таймер активен и уничтожаем
    {
        KillTimer(g_hTimer[iClient]);    // Уничтожаем таймер
        g_hTimer[iClient] = null;        // Обнуляем значения дескриптора
    }
    g_iTimer[iClient] = g_isv_talk_after_dying_time;
}

void eRound_End(Event event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(sv_deadtalk, 1, true, false);
    VoiceToAll();
    KillAllTimers();
}

void eRound_Start(Event event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(sv_deadtalk, 0, true, false);
    KillAllTimers();
}

void ePlayer_Death(Event event, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            if(GetClientTeam(i) == 2) // 2 - T | 3 - CT
            { // T Alive, so we start timer
                g_hTimer[iClient] = CreateTimer(1.0, Timer_Delay, GetClientUserId(iClient), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);    // Можем передать сразу индекс т.к. если игрок выйдет мы сразу уничтожим его таймер
                return;
            }
        }
    }
    SetConVarInt(sv_deadtalk, 1, true, false);
    KillAllTimers();
    VoiceToAll();
}

void KillAllTimers()
{
    for(int i = 1; i <= MaxClients; i++)    // Цикл по всем игрокам
    {
        if(g_hTimer[i] != INVALID_HANDLE)    // Проверяем что таймер активен
        {
            KillTimer(g_hTimer[i]);    // Уничтожаем таймер
            g_hTimer[i] = null;        // Обнуляем значения дескриптора
        }
        g_iTimer[i] = g_isv_talk_after_dying_time;
    }
}

public Action Timer_Delay(Handle hTimer, any iUserId) // Каллбек нашего таймера
{
    int iClient = GetClientOfUserId(iUserId);
    if(iClient && GetClientTeam(iClient) != 1) // Spectators
    {
        if(g_iTimer[iClient] > 0)
        {
            FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TIMER", g_iTimer[iClient]);
            PrintCenterText(iClient, sBuffer);
            g_iTimer[iClient] -= 1;
        }
        else
        {
            SetGlobalTransTarget(iClient);
            FormatEx(sBuffer, sizeof(sBuffer), "%t", "VOICE_TO_DIE");
            PrintCenterText(iClient, sBuffer);

            g_hTimer[iClient] = INVALID_HANDLE;
            return Plugin_Stop; // Останавливаем таймер
        }
    }
    else
    {
        g_hTimer[iClient] = INVALID_HANDLE;
        return Plugin_Stop; // Останавливаем таймер
    }
        
    return Plugin_Continue; // Позволяем таймеру выполнятся дальше
}

void VoiceToAll()
{
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