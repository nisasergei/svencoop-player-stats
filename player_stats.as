class PlayerStats {
    int kills = 0;
    int deaths = 0;
}

dictionary g_PlayerStats;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor("Nisa");
    g_Module.ScriptInfo.SetContactInfo("https://boosty.to/nisarium");
    
    g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
    g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientJoin );
    g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ChatHook ); // Ловим команды в чате
    
    g_Game.AlertMessage( at_console, "[MP-1] Player Stats Plugin Loaded!\n" );
}

HookReturnCode ClientJoin( CBasePlayer@ pPlayer )
{
    if ( pPlayer is null || (pPlayer.pev.flags & FL_FAKECLIENT) != 0 ) return HOOK_CONTINUE;
    
    string steamid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    if ( !g_PlayerStats.exists( steamid ) ) {
        g_PlayerStats[steamid] = PlayerStats();
    }
    return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
    if ( pPlayer is null || (pPlayer.pev.flags & FL_FAKECLIENT) != 0 ) return HOOK_CONTINUE;
    
    string victimSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    if ( g_PlayerStats.exists( victimSteamId ) ) {
        PlayerStats@ victimStats = cast<PlayerStats@>( g_PlayerStats[victimSteamId] );
        if ( victimStats !is null ) victimStats.deaths++;
    }
    
    if ( pAttacker !is null && pAttacker.IsPlayer() ) {
        CBasePlayer@ pKiller = cast<CBasePlayer@>( pAttacker );
        if ( (pKiller.pev.flags & FL_FAKECLIENT) == 0 ) {
            string killerSteamId = g_EngineFuncs.GetPlayerAuthId( pKiller.edict() );
            if ( g_PlayerStats.exists( killerSteamId ) ) {
                PlayerStats@ killerStats = cast<PlayerStats@>( g_PlayerStats[killerSteamId] );
                if ( killerStats !is null ) killerStats.kills++;
            }
        }
    }
    return HOOK_CONTINUE;
}

// Ловим сообщения в чате
HookReturnCode ChatHook( SayParameters@ pParams )
{
    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ args = pParams.GetArguments();

    // Если игрок написал "!stats" или "/stats"
    if ( args.ArgC() >= 1 && (args[0] == "!stats" || args[0] == "/stats") )
    {
        ShowStats(pPlayer);
        pParams.ShouldHide = true; // Скрываем команду из чата
        return HOOK_HANDLED;
    }
    
    return HOOK_CONTINUE;
}

void ShowStats( CBasePlayer@ pPlayer )
{
    if ( pPlayer is null ) return;
    
    string steamid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    if ( !g_PlayerStats.exists( steamid ) ) return;
    
    PlayerStats@ stats = cast<PlayerStats@>( g_PlayerStats[steamid] );
    if ( stats is null ) return;
    
    g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, 
        "[MP-1] Your Stats: Kills: " + stats.kills + " | Deaths: " + stats.deaths + "\n" );
}