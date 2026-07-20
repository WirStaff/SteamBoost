#include <amxmodx>

#define HOOK_GET_USER_IP
#include <steam_boost>

public plugin_init()
{
    register_plugin("Steam Boost Test API", "1.0.0", "Wirstaff");
}

public SteamBoost_OnUserConnectedService(const index)
{
    new buffer[64];

    get_user_ip(index, buffer, sizeof(buffer), 1);
    server_print("%d %s", SteamBoost_IsUserConnectedService(index), buffer);
}