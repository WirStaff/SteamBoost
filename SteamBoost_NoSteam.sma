#include <amxmodx>
#include <steam_boost>
#include <reapi>
#include <json>

#pragma semicolon 1
#pragma tabsize 4

#define GLOBALS: new

GLOBALS:
    _message[32];

public plugin_init()
{
    register_plugin("[Module]Steam Boost No Steam", "1.0.0", "Wirstaff & @KOH9BbIu");

    LoadConfig();
}

LoadConfig()
{
    new path[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", path, sizeof(path));
    add(path, sizeof(path), "/steam_boost/no_steam.json");

    new JSON:config = json_parse(path, true);

    json_object_get_string(config, "message", _message, sizeof(_message));

    json_free(config);
}

public SteamBoost_OnUserConnectedService(const index)
{
    if (!has_reunion() || is_user_steam(index)) {
        return;
    }

    server_cmd("kick #%d ^"%s^"", get_user_userid(index), _message);
}