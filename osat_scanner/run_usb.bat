@echo off
setlocal enabledelayedexpansion
REM Corre la app en el telefono fisico conectado por USB, sin importar a que
REM WiFi este conectada la PC. adb reverse tunelea el puerto 8001 del
REM telefono directo a 127.0.0.1 de la PC por el cable, en vez de depender
REM de la IP de red (que cambia cada vez que cambias de WiFi).
REM
REM Hay que volver a correr esto cada vez que reconectas el cable o
REM reinicias la PC -- adb reverse no es permanente.

set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe

if not exist "%ADB%" (
    echo ERROR: no se encontro adb.exe en:
    echo   %ADB%
    echo Verifica donde tienes instalado el Android SDK y ajusta esta ruta en run_usb.bat.
    exit /b 1
)

REM Detecta dispositivos fisicos conectados (ignora emuladores, que pueden
REM estar corriendo al mismo tiempo y hacen que "adb reverse" sin -s falle
REM con "more than one device/emulator").
set DEVICE_COUNT=0
set DEVICE_SERIAL=
for /f "skip=1 tokens=1,2" %%A in ('"%ADB%" devices') do (
    if "%%B"=="device" (
        echo %%A | findstr /b "emulator-" >nul
        if errorlevel 1 (
            set /a DEVICE_COUNT+=1
            set DEVICE_SERIAL=%%A
        )
    )
)

if %DEVICE_COUNT%==0 (
    echo ERROR: no se detecto ningun telefono fisico conectado por USB.
    echo Revisa el cable, que la depuracion USB este activada, y que hayas
    echo autorizado esta PC en el telefono.
    exit /b 1
)
if %DEVICE_COUNT% GTR 1 (
    echo ERROR: hay mas de un dispositivo fisico conectado. Desconecta uno o
    echo corre manualmente: adb -s ^<serial^> reverse tcp:8001 tcp:8001
    exit /b 1
)

echo Dispositivo detectado: %DEVICE_SERIAL%

"%ADB%" -s %DEVICE_SERIAL% reverse --remove-all
"%ADB%" -s %DEVICE_SERIAL% reverse tcp:8001 tcp:8001

echo.
echo Tunel USB listo (127.0.0.1:8001 del telefono -^> 127.0.0.1:8001 de la PC).
echo Asegurate de que el backend (osat_tracer) este corriendo en el puerto 8001.
echo.

flutter run -d %DEVICE_SERIAL% --dart-define=API_HOST=127.0.0.1
