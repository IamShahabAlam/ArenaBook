@echo off
rem Release build for one client: scripts\build.bat <client> [apk|appbundle] [extra flutter args]
rem The output is copied to dist\ArenaBook-<client>-<version>.<apk|aab>.
setlocal
cd /d "%~dp0.."

set "CLIENT=%~1"
set "TARGET=%~2"
if "%TARGET%"=="" set "TARGET=apk"
if "%CLIENT%"=="" goto usage
if not exist "lib\app\config\clients\%CLIENT%.dart" (
  echo Unknown client "%CLIENT%".
  goto usage
)
if /i not "%TARGET%"=="apk" if /i not "%TARGET%"=="appbundle" (
  echo Unknown target "%TARGET%". Use apk or appbundle; iOS builds need a Mac ^(scripts/build.sh^).
  goto usage
)

for /f "tokens=2" %%v in ('findstr /b "version:" pubspec.yaml') do set "VERSION=%%v"
shift & shift
set "EXTRA="
:collect
if "%~1"=="" goto build
set "EXTRA=%EXTRA% %1"
shift
goto collect

:build
echo Building %CLIENT% %TARGET% v%VERSION% ...
call flutter build %TARGET% --release --flavor %CLIENT%%EXTRA%
if errorlevel 1 exit /b 1

if not exist dist mkdir dist
if /i "%TARGET%"=="apk" (
  set "SRC=build\app\outputs\flutter-apk\app-%CLIENT%-release.apk"
  set "OUT=dist\ArenaBook-%CLIENT%-%VERSION%.apk"
) else (
  set "SRC=build\app\outputs\bundle\%CLIENT%Release\app-%CLIENT%-release.aab"
  set "OUT=dist\ArenaBook-%CLIENT%-%VERSION%.aab"
)
copy /y "%SRC%" "%OUT%" >nul || exit /b 1
echo Done: %OUT%
exit /b 0

:usage
echo Usage: scripts\build.bat ^<client^> [apk^|appbundle] [extra flutter args]
echo Clients:
for %%f in (lib\app\config\clients\*.dart) do if /i not "%%~nf"=="client_config" echo   %%~nf
exit /b 1
