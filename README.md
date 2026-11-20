# Spamton Subplot — порт на Nintendo Switch

Неофициальный некоммерческий порт фан-игры по DELTARUNE «Spamton Subplot» на Nintendo Switch (homebrew).

Игра сделана на GameMaker. На Switch её запускает [Butterscotch](https://github.com/ButterscotchRunner/Butterscotch), открытая реализация движка GameMaker, которая исполняет оригинальный `data.win` без изменений.

> Статус: **не проверено на консоли.** Сборка ещё не запускалась, известные проблемы перечислены ниже.

## Что нужно

- Nintendo Switch с кастомной прошивкой (Atmosphère) и Homebrew Menu.

## Установка

1. Скачайте `SpamtonSubplot.nro` из артефакта сборки (вкладка **Actions** → **Build Switch NRO**).
2. Скопируйте его на SD-карту в `/switch/spamton_subplot/SpamtonSubplot.nro`.
3. Запустите через Homebrew Menu (лучше в режиме полного доступа, удерживая R при запуске любой игры).

Сохранения лежат в `/switch/spamton_subplot/` на SD-карте. Туда же можно положить свой `keybinds.txt`, и он заменит встроенный.

## Сборка

Нужен devkitPro (devkitA64, libnx, switch-sdl2, switch-mesa). Проще всего собирать в официальном контейнере:

```bash
docker run --rm -v "$PWD":/work -w /work devkitpro/devkita64:latest bash switch/build.sh
```

Результат появится в `dist/SpamtonSubplot.nro`. Скрипт `switch/build.sh` скачивает Butterscotch на зафиксированном коммите, переносит сохранения в отдельную папку, кладёт файлы игры в RomFS и упаковывает NRO с иконкой из `switch/icon.jpg`.

## Известные проблемы

Butterscotch пока не реализует несколько функций GameMaker, которые использует игра:

- `font_add` — игра загружает свой шрифт `font.otf`, без этой функции текст может отображаться другим шрифтом или не отображаться совсем;
- `get_string`, `get_string_async`, `url_open` — ввод текста и открытие ссылок;
- `array_get_index`, `audio_group_get_gain`, `audio_group_stop_all`, `date_inc_day`, `ini_section_delete`, `random_get_seed`, `sprite_set_speed`, `device_mouse_dbclick_enable`.

## Лицензии

- Butterscotch распространяется под GNU AGPL v3. Исходный код, из которого собран NRO, — это указанный в `switch/build.sh` коммит Butterscotch плюс изменения из того же скрипта.
- DELTARUNE и его персонажи принадлежат Toby Fox. Это фан-проект без коммерческих целей.
