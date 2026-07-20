# SteamBoost

Набор плагинов AMX Mod X для интеграции игрового сервера Counter-Strike 1.6 с сервисом SteamBoost.

Основной плагин сообщает API о подключении и отключении игроков, хранит полученный от сервиса IP-адрес и раз в минуту отправляет статистику сервера. Дополнительные плагины могут показывать сообщения игрокам или отключать Non-Steam-клиентов.

## Состав проекта

| Файл | Назначение | Обязательность |
| --- | --- | --- |
| `SteamBoost.sma` | Основной плагин и библиотека `steam_boost` | Обязателен |
| `SteamBoost_ChatAndHud.sma` | Периодические сообщения в чат и HUD игрокам, подключённым через сервис | Опционален |
| `SteamBoost_NoSteam.sma` | Отключение Non-Steam-игроков, подключённых через сервис | Опционален |
| `Test.sma` | Пример использования API и перехвата `get_user_ip` | Только для разработки |
| `include/steam_boost.inc` | Нативы, форвард и условная подмена `get_user_ip` | Нужен для компиляции модулей |

## Зависимости

### Обязательные

- AMX Mod X. Проект проверен компилятором AMX Mod X 1.10.
- [Next21Team/AmxxEasyHttp](https://github.com/Next21Team/AmxxEasyHttp) — модуль для асинхронных HTTP-запросов и работы с JSON в основном плагине. На сервере должен быть установлен модуль EasyHttp, а при компиляции должен быть доступен `easy_http.inc`.
- Модуль `json`, входящий в современные сборки AMX Mod X, нужен дополнительным плагинам `SteamBoost_ChatAndHud` и `SteamBoost_NoSteam`.

### ReAPI и Reunion

- `SteamBoost_NoSteam.sma` требует ReAPI и работающий Reunion API.
- `SteamBoost_ChatAndHud.sma` в текущей версии также подключает `reapi.inc` при компиляции.
- Основной `SteamBoost.sma` подключает ReAPI через `#tryinclude`. При наличии ReAPI и Reunion количество лицензионных игроков в heartbeat рассчитывается через `is_user_steam`. Без этой интеграции используется количество людей без ботов и HLTV.

Проверить доступность Reunion на сервере можно командой `meta list`. Если Reunion недоступен, `has_reunion()` возвращает `false`.

## Установка

1. Установите [AmxxEasyHttp](https://github.com/Next21Team/AmxxEasyHttp/releases) на сервер и добавьте `easy_http.inc` в каталог `addons/amxmodx/scripting/include`.
2. Скопируйте `include/steam_boost.inc` в `addons/amxmodx/scripting/include`.
3. Скомпилируйте необходимые `.sma`-файлы.
4. Скопируйте полученные `.amxx` в `addons/amxmodx/plugins`.
5. Скопируйте каталог `configs/steam_boost` в `addons/amxmodx/configs`.
6. Укажите адрес API и токен в `configs/steam_boost/core.json`.
7. Добавьте плагины в `plugins.ini`. Основной плагин должен находиться выше дополнительных:

```ini
SteamBoost.amxx
SteamBoost_ChatAndHud.amxx
SteamBoost_NoSteam.amxx
```

`Test.amxx` устанавливать на рабочий сервер не требуется.

## Основной плагин — SteamBoost.sma

При подключении игрока плагин отправляет его SteamID запросом `POST /players/connect`. Если API возвращает `via_the_service: true`, плагин:

- помечает игрока как подключённого через SteamBoost;
- сохраняет значение `player_ip`;
- увеличивает счётчик подключённых через сервис игроков;
- вызывает форвард `SteamBoost_OnUserConnectedService`.

При отключении такого игрока отправляется `POST /players/disconnect`.

Раз в 60 секунд на `POST /heartbeat` передаются:

- `current_players` — текущее количество игроков;
- `max_players` — максимальное количество слотов;
- `bots` — количество ботов;
- `current_license` — количество лицензионных игроков;
- `current_service` — количество игроков, подключённых через SteamBoost.

### Конфигурация core.json

```json
{
    "api_url": "https://server-api.steam-boost.ru/v1",
    "api_token": ""
}
```

| Параметр | Описание |
| --- | --- |
| `api_url` | Базовый адрес SteamBoost API |
| `api_token` | Токен сервера, передаваемый в заголовке `Authorization: Bearer ...` |

## Chat & HUD — SteamBoost_ChatAndHud.sma

Плагин запоминает игроков через форвард `SteamBoost_OnUserConnectedService` и с интервалом `delay_sec` показывает им настроенные сообщения.

### Конфигурация chat_and_hud.json

```json
{
    "chat": {
        "enabled": true,
        "message": "!gПЕРЕЗАЙДИ ПО НАСТОЯЩИМУ IP: !t",
        "is_dead_user": true
    },
    "hud": {
        "enabled": true,
        "message": "ХОЧЕШЬ ИГРАТЬ С КОМФОРТНЫМ ПИНГОМ?^nПЕРЕХОДИ ПО НАСТОЯЩЕМУ IP:",
        "colors": {
            "red": 0,
            "green": 100,
            "blue": 0
        },
        "positions": {
            "x": -1.0,
            "y": 0.3
        },
        "is_dead_user": true
    },
    "delay_sec": 1.0
}
```

- `enabled` включает соответствующий тип сообщения.
- `is_dead_user: true` показывает сообщение только мёртвым игрокам. При `false` сообщение показывается независимо от состояния игрока.
- В сообщении чата поддерживаются цвета: `!n` — обычный, `!t` — цвет команды, `!g` — зелёный.
- `^n` в HUD-сообщении создаёт новую строку.
- `colors` задаёт RGB-цвет HUD.
- `positions` задаёт координаты HUD. Значение `x: -1.0` центрирует сообщение по горизонтали.
- `delay_sec` задаёт интервал показа в секундах.

## No Steam — SteamBoost_NoSteam.sma

После подтверждения подключения через SteamBoost плагин проверяет тип авторизации клиента через Reunion. Если игрок не является Steam-клиентом, он отключается от сервера с сообщением из конфигурации.

Если Reunion API недоступен, плагин не выполняет отключение.

### Конфигурация no_steam.json

```json
{
    "message": "Steam reject"
}
```

`message` — причина, отображаемая игроку при отключении.

## API для других плагинов

Подключение API:

```pawn
#include <amxmodx>
#include <steam_boost>
```

### SteamBoost_IsUserConnectedService

```pawn
native bool:SteamBoost_IsUserConnectedService(const index);
```

Возвращает `true`, если API подтвердил, что игрок с указанным индексом подключён через SteamBoost. До завершения асинхронного запроса возвращает `false`.

### SteamBoost_GetUserAddress

```pawn
native SteamBoost_GetUserAddress(const index, buffer[], len);
```

Записывает IP игрока в `buffer` и возвращает количество записанных символов. Для игрока SteamBoost используется адрес, полученный от API. Для остальных игроков используется адрес игрового соединения без порта.

Пример:

```pawn
new address[64];
SteamBoost_GetUserAddress(index, address, sizeof(address));
```

### SteamBoost_OnUserConnectedService

```pawn
forward SteamBoost_OnUserConnectedService(const index);
```

Вызывается после того, как API подтвердил подключение игрока через SteamBoost. Форвард асинхронный относительно `client_putinserver`: к моменту его вызова игрок уже может находиться на сервере некоторое время.

Пример обработчика:

```pawn
public SteamBoost_OnUserConnectedService(const index)
{
    server_print("Игрок %d подключён через SteamBoost", index);
}
```

## Условная подмена get_user_ip

Инклуд может прозрачно подменить стандартный `get_user_ip`. Для этого определите `HOOK_GET_USER_IP` строго перед подключением `steam_boost`:

```pawn
#include <amxmodx>

#define HOOK_GET_USER_IP
#include <steam_boost>
```

После этого обычные вызовы менять не нужно:

```pawn
new address[64];
get_user_ip(index, address, sizeof(address), true);
```

Если игрок подключён через SteamBoost, будет вызван `SteamBoost_GetUserAddress`. Для остальных игроков будет вызван оригинальный `get_user_ip` с сохранением параметра `without_port`.

Если `HOOK_GET_USER_IP` не определён, инклуд никак не изменяет стандартный `get_user_ip`.

## Диагностика

- `Invalid native` или `Module "easy_http" required` означает, что модуль AmxxEasyHttp не установлен либо не загружен.
- `Library "steam_boost" required` означает, что основной `SteamBoost.amxx` не загружен или расположен ниже зависимого плагина в `plugins.ini`.
- `[ReAPI] Reunion: isn't available` означает, что Reunion API недоступен. Проверьте состояние Reunion через `meta list` и не вызывайте Reunion-нативы без проверки `has_reunion()`.
- Ошибки HTTP записываются в `addons/amxmodx/logs/steam_boost.log`.
