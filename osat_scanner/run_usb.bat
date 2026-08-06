@echo off
REM Corre la app en el telefono fisico conectado por USB, sin importar a que
REM WiFi este conectada la PC. adb reverse tunelea el puerto 8001 del
REM telefono directo a 127.0.0.1 de la PC por el cable, en vez de depender
REM de la IP de red (que cambia cada vez que cambias de WiFi).
REM
REM Hay que volver a correr esto cada vez que reconectas el cable o
REM reinicias la PC -- adb reverse no es permanente.

set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"

%ADB% wait-for-device
%ADB% reverse tcp:8001 tcp:8001

echo.
echo Tunel USB listo (127.0.0.1:8001 del telefono -> 127.0.0.1:8001 de la PC).
echo Asegurate de que el backend (osat_tracer) este corriendo en el puerto 8001.
echo.

flutter run --dart-define=API_HOST=127.0.0.1
