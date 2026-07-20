#include <amxmodx>
#include <amxmisc>
#include <easy_http>
#tryinclude <reapi>

#pragma semicolon 1
#pragma tabsize 4

#define GLOBALS: new
#define let new

enum 
{
    USER_ID,
}

GLOBALS:
    _apiUrl[256],
    _apiToken[256],
    bool:_isUserConnectedService[MAX_PLAYERS + 1],
    userAddressFromService[MAX_PLAYERS + 1][64],
    _usersConnectedViaService,
    _forwardOnUserConnectedService;

public plugin_init()
{
    register_plugin("Steam Boost", "3.0.0", "Wirstaff", "https://steam-boost.ru");

    LoadConfig();

    _forwardOnUserConnectedService = CreateMultiForward("SteamBoost_OnUserConnectedService", ET_IGNORE, FP_CELL);

    set_task(60.0, "OnHeartbeat", .flags = "b");
}

public OnHeartbeat()
{
    HeartbeatRequest();
}

public plugin_natives()
{
    register_library("steam_boost");

    register_native("SteamBoost_IsUserConnectedService", "NativeIsUserConnectedService");
    register_native("SteamBoost_GetUserAddress", "NativeGetUserAddress");
}

public NativeIsUserConnectedService(plugin_id, argc)
{
    let index = get_param(1);
    return _isUserConnectedService[index];
}

public NativeGetUserAddress(plugin_id, argc)
{
    let index = get_param(1);
    let len = get_param(3);

    if (_isUserConnectedService[index]) {
        return set_string(2, userAddressFromService[index], len);
    } 

    let buffer[64];
    get_user_ip(index, buffer, sizeof(buffer), true);

    return set_string(2, buffer, len);
}

OnUserConnectedService(const index)
{
    ExecuteForward(_forwardOnUserConnectedService, _, index);
}

public client_putinserver(index)
{
    if (is_user_bot(index)) {
        return;
    }

    _isUserConnectedService[index] = false;

    let buffer[64];
    get_user_authid(index, buffer, sizeof(buffer));

    ClientConnectRequest(index, buffer);
}

public client_disconnected(index, bool:drop, message[], maxlen)
{
    if (drop && _isUserConnectedService[index]) {
        _usersConnectedViaService--;
        let buffer[64];
        get_user_authid(index, buffer, sizeof(buffer));
        ClientDisconnectRequest(buffer);
    }
}

HeartbeatRequest()
{
    let EzHttpOptions:optionsId = GetCommonRequestOptions();

    let EzJSON:body = ezjson_init_object();

    ezjson_object_set_number(body, "current_players", get_playersnum_ex(GetPlayers_IncludeConnecting));
    ezjson_object_set_number(body, "max_players", get_maxplayers());
    ezjson_object_set_number(body, "bots", get_playersnum_ex(GetPlayers_ExcludeHuman));

    let count = get_playersnum_ex(GetPlayers_IncludeConnecting | GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV);
    #if defined _reapi_reunion_included
        if (has_reunion()) {
            count = 0;
            for (let i = 0; i <= MaxClients; i++) {
                if (is_user_steam(i)) {
                    count++;
                }  
            }
        } 

        ezjson_object_set_number(body, "current_license", count);
    #endif

    ezjson_object_set_number(body, "current_license", count);

    ezjson_object_set_number(body, "current_service", _usersConnectedViaService);

    ezhttp_option_set_body_from_json(optionsId, body);
    
    let url[sizeof(_apiUrl) * 2];
    formatex(url, sizeof(url), "%s/heartbeat", _apiUrl);

    ezhttp_post(url, "OnHeartbeatResponse", optionsId);
    ezjson_free(body);
}

public OnHeartbeatResponse(EzHttpRequest:requestId)
{
    let buffer[512];
    ezhttp_get_user_data(requestId, buffer);

    if (ezhttp_get_error_code(requestId) != EZH_OK) {
        ezhttp_get_error_message(requestId, buffer, sizeof(buffer));
        log_to_file("steam_boost.log", buffer);
    }
}

ClientConnectRequest(const index, const steamId[])
{
    let EzHttpOptions:optionsId = GetCommonRequestOptions();

    let buffer[1];
    buffer[USER_ID] = get_user_userid(index);
    ezhttp_option_set_user_data(EzHttpOptions:optionsId, buffer, sizeof(buffer));

    let EzJSON:body = ezjson_init_object();

    ezjson_object_set_string(body, "steam_id", steamId);

    ezhttp_option_set_body_from_json(optionsId, body);

    let url[sizeof(_apiUrl) * 2];
    formatex(url, sizeof(url), "%s/players/connect", _apiUrl);
    ezhttp_post(url, "OnClientConnectResponse", optionsId);

    ezjson_free(body);
}

public OnClientConnectResponse(EzHttpRequest:requestId)
{
    let buffer[512];
    ezhttp_get_user_data(requestId, buffer);

    if (ezhttp_get_error_code(requestId) != EZH_OK) {
        ezhttp_get_error_message(requestId, buffer, sizeof(buffer));
        log_to_file("steam_boost.log", buffer);
        return;
    }

    if (ezhttp_get_http_code(requestId) != 200) {
        return;
    }

    let index = GetIndexByUserId(buffer[USER_ID]);
    
    if (!index) {
        return;
    }

    ezhttp_get_data(requestId, buffer, sizeof(buffer));
    let EzJSON:body = ezjson_parse(buffer);

    let bool:isViaTheService = ezjson_object_get_bool(body, "via_the_service");

    if (isViaTheService) {
        ezjson_object_get_string(body, "player_ip", userAddressFromService[index], sizeof(userAddressFromService[]));
        _isUserConnectedService[index] = true;
        _usersConnectedViaService++;
        OnUserConnectedService(index);
    }

    ezjson_free(body);
}

ClientDisconnectRequest(const steamId[])
{
    let EzHttpOptions:optionsId = GetCommonRequestOptions();

    let EzJSON:body = ezjson_init_object();

    ezjson_object_set_string(body, "steam_id", steamId);

    ezhttp_option_set_body_from_json(optionsId, body);

    let url[sizeof(_apiUrl) * 2];
    formatex(url, sizeof(url), "%s/players/disconnect", _apiUrl);
    ezhttp_post(url, "OnClientDisconnectResponse", optionsId);

    ezjson_free(body);
}

public OnClientDisconnectResponse(EzHttpRequest:requestId)
{
    let buffer[512];
    ezhttp_get_user_data(requestId, buffer);

    if (ezhttp_get_error_code(requestId) != EZH_OK) {
        ezhttp_get_error_message(requestId, buffer, sizeof(buffer));
        log_to_file("steam_boost.log", buffer);
    }
}

LoadConfig() 
{
    let path[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", path, sizeof(path));
    add(path, sizeof(path), "/steam_boost/core.json");

    let EzJSON:config = ezjson_parse(path, true);

    ezjson_object_get_string(config, "api_url", _apiUrl, sizeof(_apiUrl));
    ezjson_object_get_string(config, "api_token", _apiToken, sizeof(_apiToken));

    ezjson_free(config);
}

EzHttpOptions:GetCommonRequestOptions()
{

    let EzHttpOptions:optionsId = ezhttp_create_options();
    let buffer[sizeof(_apiToken) * 2];
    formatex(buffer, sizeof(buffer), "Bearer %s", _apiToken);
    ezhttp_option_set_header(optionsId, "Authorization", buffer);
    ezhttp_option_set_header(optionsId, "Content-Type", "application/json");
    ezhttp_option_set_header(optionsId, "Accept", "application/json");

    ezhttp_option_set_plugin_end_behaviour(optionsId, EZH_FORGET_REQUEST);

    return optionsId;
}

GetIndexByUserId(const userId)
{
    return find_player_ex(FindPlayer_MatchUserId | FindPlayer_IncludeConnecting, userId);
}
