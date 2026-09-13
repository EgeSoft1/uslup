@echo off
chcp 65001 >nul
title Uslup - Sunum
rem ===========================================================================
rem  Üslup — sunum başlatıcı (internet GEREKMEZ)
rem
rem  1. Derlenmiş web sürümünü bu bilgisayarda yerel bir sunucuyla açar.
rem  2. Edge'i adres çubuğu olmayan bir uygulama penceresinde başlatır.
rem     Tam ekran için pencerede F11'e basın.
rem
rem  Önkoşul (bir kez, internet varken):
rem     cd mobile
rem     flutter build web --release --no-web-resources-cdn
rem ===========================================================================

set "KOK=%~dp0"
set "DART=dart"
where dart >nul 2>nul || set "DART=C:\flutter\bin\cache\dart-sdk\bin\dart.exe"

if not exist "%KOK%mobile\build\web\index.html" (
  echo [!] mobile\build\web bulunamadi.
  echo     Once su komutlari calistirin:
  echo       cd mobile
  echo       flutter build web --release --no-web-resources-cdn
  pause
  exit /b 1
)

start "Uslup sunucusu" /min "%DART%" "%KOK%mobile\tool\sunum_sunucusu.dart"
timeout /t 3 /nobreak >nul

start "" msedge --app=http://127.0.0.1:8123 --start-maximized --new-window
if errorlevel 1 start "" http://127.0.0.1:8123
