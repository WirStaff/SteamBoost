#include <amxmodx>
#include <easy_http>

#pragma semicolon 1
#pragma tabsize 4

#define GLOBALS: new

enum 
{
    USER_ID,
}

GLOBALS:
    _apiUrl[256],
    _apiToken[256],
    bool:_isUserConnectedService[MAX_PLAYERS + 1],
    _forwardOnUserConnectedService;

public plugin_init()
{
    register_plugin("Steam Boost", "2.0.0", "Wirstaff", "https://steam-boost.ximply.ru");

    LoadConfig();

    _forwardOnUserConnectedService = CreateMultiForward("SteamBoost_OnUserConnectedService", ET_IGNORE, FP_CELL);
}

public plugin_natives()
{
    register_library("steam_boost");

    register_native("SteamBoost_IsUserConnectedService", "NativeIsUserConnectedService");
    register_native("SteamBoost_GetUserAddress", "NativeGetUserAddress");
}

public NativeIsUserConnectedService(plugin_id, argc)
{
    new index = get_param(1);
    return _isUserConnectedService[index];
}

//deprecated
public NativeGetUserAddress(plugin_id, argc)
{
    //new index = get_param(1);
    new len = get_param(3);
    set_string(2, "0.0.0.0", len);
}

OnUserConnectedService(const index)
{
    ExecuteForward(_forwardOnUserConnectedService, _, index);
}

public client_authorized(index, const authid[])
{
    if (is_user_bot(index)) {
        return;
    }

    _isUserConnectedService[index] = false;

    ClientConnectRequest(index, authid);
}

ClientConnectRequest(const index, const steamId[])
{
    new EzHttpOptions:optionsId = GetCommonRequestOptions();

    new buffer[1];
    buffer[USER_ID] = get_user_userid(index);
    ezhttp_option_set_user_data(EzHttpOptions:optionsId, buffer, sizeof(buffer));

    new url[sizeof(_apiUrl) * 2];
    formatex(url, sizeof(url), "%s/v1/server/check-player/%s", _apiUrl, steamId);

    ezhttp_get(url, "OnClientConnectResponse", optionsId);
}

public OnClientConnectResponse(EzHttpRequest:requestId)
{
    new buffer[512];
    ezhttp_get_user_data(requestId, buffer);

    if (ezhttp_get_error_code(requestId) != EZH_OK) {
        ezhttp_get_error_message(requestId, buffer, sizeof(buffer));
        log_to_file("steam_boost.log", buffer);
        return;
    }

    if (ezhttp_get_http_code(requestId) != 200) {
        return;
    }

    new index = GetIndexByUserId(buffer[USER_ID]);
    if (!index) {
        return;
    }

    ezhttp_get_data(requestId, buffer, sizeof(buffer));
    new EzJSON:response = ezjson_parse(buffer);

    new EzJSON:data = ezjson_object_get_value(response, "data");

    new isViaBoost = ezjson_object_get_bool(data, "via_boost");

    if (isViaBoost) {
        _isUserConnectedService[index] = true;
        OnUserConnectedService(index);
    }

    ezjson_free(data);
    ezjson_free(response);
}

LoadConfig() 
{
    new path[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", path, sizeof(path));
    add(path, sizeof(path), "/steam_boost/core.json");

    new EzJSON:config = ezjson_parse(path, true);

    ezjson_object_get_string(config, "api_url", _apiUrl, sizeof(_apiUrl));
    ezjson_object_get_string(config, "api_token", _apiToken, sizeof(_apiToken));

    ezjson_free(config);
}

EzHttpOptions:GetCommonRequestOptions()
{

    new EzHttpOptions:optionsId = ezhttp_create_options();

    ezhttp_option_set_header(optionsId, "X-Api-Key", _apiToken);

    ezhttp_option_set_plugin_end_behaviour(optionsId, EZH_FORGET_REQUEST);

    return optionsId;
}

GetIndexByUserId(const userId)
{
    for (new i = 1; i <= MaxClients; i++) {
        if (is_user_connecting(i) && get_user_userid(i) == userId) {
            return i;
        }   
    }
        
    return 0;
}