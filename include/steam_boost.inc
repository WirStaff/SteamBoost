#if defined _steam_boost_included
	#endinput
#endif
#define _steam_boost_included

/*
    Вызывается, когда игрок подключается через сервис
*/
forward SteamBoost_OnUserConnectedService(const index);

/*
    Возвращает true, если игрок подключен через сервис
*/
native bool:SteamBoost_IsUserConnectedService(const index);

/*
    Отдает IP игрока
*/
native SteamBoost_GetUserAddress(const index, buffer[], len);

#if defined HOOK_GET_USER_IP
stock SteamBoost_GetUserIp(const index, buffer[], len, withoutPort = 0)
{
    if (SteamBoost_IsUserConnectedService(index)) {
        return SteamBoost_GetUserAddress(index, buffer, len);
    }

    return get_user_ip(index, buffer, len, withoutPort);
}

#define get_user_ip SteamBoost_GetUserIp
#endif

#pragma reqlib steam_boost
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib steam_boost
#endif
