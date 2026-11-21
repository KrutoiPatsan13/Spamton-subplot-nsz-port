@echo off
rem Same as make_nsz.bat, with the Russian translation built in.
cd /d "%~dp0"
if not exist romfs_ru (
    xcopy /e /i /q romfs romfs_ru >nul
    xcopy /e /i /q russian_lang romfs_ru\lang >nul
)
call make_nsz.bat ru
