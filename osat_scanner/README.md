# OSAT Tracer — App Móvil (Flutter)

App para operadores de línea de producción. Cubre los requerimientos RFM01–RFM08.

## Setup inicial

```bash
# 1. Crear el proyecto Flutter (si no existe ya en tu repo)
flutter create osat_tracer_mobile
cd osat_tracer_mobile

# 2. Reemplaza el pubspec.yaml generado por el de este paquete
#    y copia toda la carpeta lib/ reemplazando la que crea flutter create

# 3. Instalar dependencias
flutter pub get
```

## Estructura de archivos

```
lib/
├── main.dart                      # Entry point + lifecycle (RFM01 timeout)
├── models/
│   ├── empleado.dart               # Perfil del operador (RFM03)
│   ├── lote.dart                   # Oblea del backend = "Lote" en UI
│   ├── etapa.dart                  # Paso del proceso con su estado
│   ├── defecto.dart                # Catálogo + registro de defectos (RFM06)
│   └── alerta_operador.dart        # Notificaciones (RFM08)
├── services/
│   ├── api_client.dart             # HTTP base + manejo de token
│   ├── auth_service.dart           # Login/logout/perfil (RFM01-03)
│   ├── lote_service.dart           # Buscar/registrar etapa/hold (RFM04-07)
│   └── alerta_service.dart         # Listar alertas (RFM08)
├── providers/
│   ├── auth_provider.dart          # Estado de sesión global
│   └── lote_provider.dart          # Estado del lote activo
├── widgets/
│   ├── osat_bottom_nav.dart        # Nav bar: Inicio/Escanear/Alertas/Perfil
│   ├── badge_estado.dart           # Pills de estado (Aprobado/Hold/etc)
│   ├── lote_header_card.dart       # Card con dies/scrap/yield
│   ├── trazabilidad_stepper.dart   # Lista de etapas con su estado visual
│   └── osat_toast.dart             # Toasts (éxito/error/warning/info)
├── screens/
│   ├── splash_screen.dart          # Decide Login vs Home al abrir
│   ├── login_screen.dart           # RFM01
│   ├── home_screen.dart            # Último lote + búsqueda manual
│   ├── scanner_screen.dart         # RFM04 — Cámara QR con mobile_scanner
│   ├── completar_etapa_screen.dart # RFM05, RFM06, RFM07
│   ├── hold_screen.dart            # RFM05 — Bloquear lote
│   ├── alertas_screen.dart         # RFM08
│   └── perfil_screen.dart          # RFM03 + RFM02 (logout)
└── utils/
    └── constants.dart              # Colores, ApiConfig, estilos
```

## Configurar la URL del backend

En `lib/utils/constants.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8001/api';
  // 10.0.2.2 = localhost de tu PC, visto desde el emulador Android.
  // Si pruebas en celular físico conectado a la misma WiFi que tu PC,
  // cambia esto a tu IP local, ej: 'http://192.168.1.50:8001/api'
  // y corre el backend con: python manage.py runserver 0.0.0.0:8001
}
```

## Permisos necesarios

### Android — `android/app/src/main/AndroidManifest.xml`
Agrega dentro de `<manifest>`, antes de `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS — `ios/Runner/Info.plist`
Agrega dentro de `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos la cámara para escanear códigos QR de los lotes</string>
```

## Correr la app

```bash
# Emulador Android (asegúrate que el backend corra en 0.0.0.0:8001)
flutter run

# Ver dispositivos disponibles
flutter devices

# Correr en un dispositivo específico
flutter run -d <device_id>
```

## Endpoints del backend que la app consume

| Función | Endpoint | Método |
|---|---|---|
| Login | `/api/v1/auth/login/` | POST |
| Logout | `/api/v1/auth/logout/` | POST |
| Perfil | `/api/v1/list/empleados/` | GET |
| Buscar lote | `/api/v1/detail/Oblea/<numero>/` | GET |
| Registrar etapa | `/api/v1/create/PasoRealizado/` | POST |
| Poner en Hold | `/api/v1/update/Oblea/<numero>/` | PATCH |
| Catálogo defectos | `/api/v1/list/Defecto/` | GET |
| Alertas | `/api/v1/list/historiales_alertas/` | GET |

## Pendientes del backend para que la app funcione al 100%

- [ ] El endpoint `detail/Oblea/<pk>/` debe incluir el array `etapas` con
      `codigo`, `nombre`, `estado`, `operador`, `maquina`, `hora_inicio`, `hora_fin`
- [ ] El endpoint `update/Oblea/<pk>/` debe aceptar `hold_motivo` como campo
- [ ] `create/PasoRealizado/` debe aceptar el array `defectos` con
      `defecto`, `cantidad`, `accion`, `foto`
- [ ] Validar en backend: no permitir registrar etapa si la anterior no está
      Aprobada, y bloquear si el lote está en Hold (la app ya valida esto
      localmente en `LoteService.registrarEtapa`, pero el backend debe ser
      la fuente de verdad)

## Notas de diseño

Los colores y el design system replican exactamente el frontend web
(`osat.css`) para mantener consistencia visual entre admin/supervisor (web)
y operador (móvil).
