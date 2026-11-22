# Spamton Subplot — сборка NSP/NSZ для установки через DBI

Этот набор превращается в устанавливаемую игру (иконка на главном экране Switch, запуск без Homebrew Menu, вся память консоли). Для упаковки нужны ключи **вашей** консоли — их нельзя распространять, поэтому готовый NSZ собирается у вас.

- Title ID: `01a57b0758b70000`
- Работает на любой Switch с Atmosphère (обычная, OLED, Lite; любая прошивка — используется keygeneration 1).
- Нужны сигпатчи (например, sys-patch) — как для любой самодельной NSP.

## 1. Достаньте ключи (один раз)

Запустите [Lockpick_RCM](https://github.com/saneki/Lockpick_RCM) через Hekate (Payloads), выберите «Dump from SysNAND». Файл появится на SD-карте: `/switch/prod.keys`. Скопируйте его на ПК.

## 2. Соберите NSZ на Windows

1. Распакуйте этот архив в любую папку.
2. Положите рядом с `make_nsz.bat`:
   - `prod.keys` из шага 1;
   - `hacbrewpack.exe` (hacBrewPack 3.05, исходники: https://github.com/xitrix/hacbrewpack).
3. Для NSZ установите Python и выполните `pip install nsz`. Без этого получится только NSP — DBI его тоже устанавливает.
4. Запустите:
   - `make_nsz.bat` — английская версия;
   - `make_nsz_ru.bat` — с русификатором внутри.
5. Готовые файлы — в папке `out`.

## 3. Установка через DBI

1. Скопируйте `.nsz` (или `.nsp`) на SD-карту, например в `/nsp/`.
2. Откройте DBI → «Browse SD Card» → выберите файл → «Install».
3. Игра появится на главном экране с иконкой Спамтона.

Сохранения лежат на SD-карте в `/switch/spamton_subplot/` — общие с версией для Homebrew Menu. Туда же можно положить папку `lang` русификатора: она работает и с английской NSZ.

## Если не запускается

- **Fatal error 2128-0007 (program 0100000000000023)** при запуске — это пакет, собранный старым набором без логотипа запуска (`--nologo`). Прошивки последних версий падают на нём. Удалите игру (DBI → «Browse installed applications» → Spamton Subplot → «Delete»), скачайте новый набор (в нём есть папка `logo`) и пересоберите NSZ.
- **«Не удалось запустить программу» / 2002-xxxx** — устарели сигпатчи: обновите sys-patch под вашу прошивку и Atmosphère.
- Если игра вылетела, приложите свежий файл из `/atmosphere/crash_reports/` (или `/atmosphere/fatal_reports/`) и `/switch/spamton_subplot/log.txt`.

Папку `logo` из набора не удаляйте: без неё консоль не сможет показать заставку при запуске (её создаёт `switch/nsp/make_logo.py`).

## Если не хотите ничего собирать на ПК

Можно собрать NSZ прямо на GitHub: в репозитории порта откройте **Settings → Secrets and variables → Actions → New repository secret**, назовите секрет `PROD_KEYS` и вставьте содержимое своего `prod.keys`. Затем **Actions → Build Switch NRO → Run workflow**. Готовые NSZ появятся в артефакте `SpamtonSubplot-NSZ`. Ключи остаются в секретах вашего репозитория и в артефакты не попадают.
