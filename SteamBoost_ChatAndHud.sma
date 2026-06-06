#include <amxmodx>
#include <steam_boost>
#include <reapi>
#include <json>

#pragma semicolon 1
#pragma tabsize 4

#define GLOBALS: new

enum 
{
    R,
    G,
    B,
    COLOR_SIZE
}

enum 
{
    X,
    Y,
    POSITION_SIZE
}

GLOBALS:
    bool:_userConnectedService[MAX_PLAYERS + 1],
    bool:_chatEnabled,
    _chatMessage[128],
    bool:_chatIsDeadUser,
    bool:_hudEnabled,
    _hudMessage[128],
    _hudColors[COLOR_SIZE],
    Float:_hudPositions[POSITION_SIZE],
    bool:_hudIsDeadUser,
    Float:_delaySec;

public plugin_init()
{
    register_plugin("[Module]Steam Boost Chat & Hud", "1.1.0", "Wirstaff & @KOH9BbIu", "https://t.me/steam_boost_bot");

    LoadConfig();

    set_task(_delaySec, "@OnFloodMessage", .flags="b");
}

public @OnFloodMessage(taskId)
{
    static isAlive = false;
    for (new i = 1; i <= MaxClients; i++) {
        if (!_userConnectedService[i]) {
            continue;
        }

        isAlive = is_user_alive(i);

        if (_chatEnabled) {
            if (!_chatIsDeadUser) {
                SendChatMessage(i);
            } 

            if (_chatIsDeadUser && !isAlive) {
                SendChatMessage(i);
            }
        }

        if (_hudEnabled) {
            if (!_hudIsDeadUser) {
                SendHudMessage(i);
            } 

            if (_hudIsDeadUser && !isAlive) {
                SendHudMessage(i);
            }
        }
    }
}

SendChatMessage(const index) 
{
    client_print_color(index, 0, _chatMessage);
}

SendHudMessage(const index)
{
    set_dhudmessage(
        _hudColors[R], 
        _hudColors[G], 
        _hudColors[B], 
        Float:_hudPositions[X], 
        Float:_hudPositions[Y], 
        .fadeintime=_delaySec
    );
    
    show_dhudmessage(index, _hudMessage);
}

LoadConfig()
{
    new path[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", path, sizeof(path));
    add(path, sizeof(path), "/steam_boost/chat_and_hud.json");

    new JSON:config = json_parse(path, true);

    new JSON:module = json_object_get_value(config, "chat");

    _chatEnabled = json_object_get_bool(module, "enabled");
    json_object_get_string(module, "message", _chatMessage, sizeof(_chatMessage));
    replace_string(_chatMessage, sizeof(_chatMessage), "!n", "^1");
    replace_string(_chatMessage, sizeof(_chatMessage), "!t", "^3");
    replace_string(_chatMessage, sizeof(_chatMessage), "!g", "^4");
    _chatIsDeadUser = json_object_get_bool(module, "is_dead_user");

    json_free(module);

    module = json_object_get_value(config, "hud");

    _hudEnabled = json_object_get_bool(module, "enabled");
    json_object_get_string(module, "message", _hudMessage, sizeof(_hudMessage));
    replace_string(_hudMessage, sizeof(_hudMessage), "^^n", "^n");

    new JSON:colors = json_object_get_value(module, "colors");
    _hudColors[R] = json_object_get_number(colors, "red");
    _hudColors[G] = json_object_get_number(colors, "green");
    _hudColors[B] = json_object_get_number(colors, "blue");
    json_free(colors);

    new JSON:positions = json_object_get_value(module, "positions");
    _hudPositions[X] = json_object_get_real(positions, "x");
    _hudPositions[Y] = json_object_get_real(positions, "y");
    json_free(positions);

    _hudIsDeadUser = json_object_get_bool(module, "is_dead_user");

    json_free(module);
    
    _delaySec = json_object_get_real(config, "delay_sec");

    json_free(config);
}

public SteamBoost_OnUserConnectedService(const index)
{
    _userConnectedService[index] = true;
}

public client_disconnected(index, bool:drop, message[], maxlen)
{
    if (drop) {
        _userConnectedService[index] = false;
    }
}