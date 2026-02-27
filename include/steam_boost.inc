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
    Получает настоящий ИП игрока, даже если он играет через сервис
*/
native SteamBoost_GetUserAddress(const index, buffer[], len);

#pragma reqlib steam_boost
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib steam_boost
#endif