@echo off
rem Builds "SpamtonSubplot [01a57b0758b70000][v0].nsp" and .nsz from this kit.
rem Put next to this file: hacbrewpack.exe and prod.keys dumped from YOUR console (Lockpick_RCM).
rem For the .nsz you also need nsz (https://github.com/nicoboss/nsz): pip install nsz
setlocal
cd /d "%~dp0"
if not exist hacbrewpack.exe ( echo hacbrewpack.exe not found next to this script & pause & exit /b 1 )
if not exist prod.keys ( echo prod.keys not found next to this script & pause & exit /b 1 )
if not exist logo\StartupMovie.gif ( echo the logo folder is missing - unpack the whole kit & pause & exit /b 1 )
set ROMFS=romfs
set NAME=SpamtonSubplot
if /i "%~1"=="ru" ( set ROMFS=romfs_ru& set NAME=SpamtonSubplot_RU )
if exist out_tmp rmdir /s /q out_tmp
hacbrewpack.exe -k prod.keys --titleid 01a57b0758b70000 --keygeneration 1 --logodir logo --exefsdir exefs --romfsdir %ROMFS% --controldir control --tempdir out_tmp\temp --ncadir out_tmp\nca --backupdir out_tmp\backup --nspdir out_tmp\nsp
if errorlevel 1 ( echo hacbrewpack failed & pause & exit /b 1 )
if not exist out mkdir out
for %%f in (out_tmp\nsp\*.nsp) do move /y "%%f" "out\%NAME% [01a57b0758b70000][v0].nsp" >nul
rmdir /s /q out_tmp
echo NSP: out\%NAME% [01a57b0758b70000][v0].nsp
where nsz >nul 2>nul
if errorlevel 1 ( echo nsz is not installed - the NSP above also installs with DBI. & pause & exit /b 0 )
if not exist "%USERPROFILE%\.switch" mkdir "%USERPROFILE%\.switch"
if not exist "%USERPROFILE%\.switch\prod.keys" copy prod.keys "%USERPROFILE%\.switch\prod.keys" >nul
rem nsz names its output after the title ID, which both variants share: compress into a separate folder and rename.
if exist out_nsz rmdir /s /q out_nsz
nsz -C -o out_nsz "out\%NAME% [01a57b0758b70000][v0].nsp"
for %%f in (out_nsz\*.nsz) do move /y "%%f" "out\%NAME% [01a57b0758b70000][v0].nsz" >nul
rmdir /s /q out_nsz
echo Done. Files are in the "out" folder.
pause
