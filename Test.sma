#include <amxmodx>
#include <steam_boost>


public plugin_init()
{
    register_plugin("Steam Boost Test API", "1.0.0", "Wirstaff");
}

public SteamBoost_OnUserConnectedService(const index)
{
    new buffer[64];

    SteamBoost_GetUserAddress(index, buffer, sizeof(buffer));

    server_print("%d %s", SteamBoost_IsUserConnectedService(index), buffer);
}