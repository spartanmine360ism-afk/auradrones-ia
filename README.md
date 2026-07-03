# Aura Drones IA

App Flutter premium para pilotos de drones, creadores de contenido aereo y vuelos mas seguros.

## Incluye

- Arquitectura modular en `lib/core` y `lib/features`.
- Material 3, tema oscuro glassmorphism y componentes reutilizables.
- Navegacion completa con GoRouter.
- Estado con Riverpod.
- Home Dashboard, clima, Fly Score, Aura IA, mapa, drones, baterias, planeador, academia, historial, perfil y ajustes.
- Ubicacion real con `geolocator` y `geocoding`, con permisos Android/iOS y manejo de errores.
- Clima real con OpenWeather y fallback mock cuando no hay `WEATHER_API_KEY`.
- Aura IA conectable a OpenAI con contexto de clima, ubicacion, KP, Fly Score, dron y bateria.
- Google Maps Flutter integrado con ubicacion actual y capas preparadas para zonas/NOTAM.
- API keys por `--dart-define`, sin secretos en el codigo.

## Ejecutar

```bash
flutter pub get
flutter run \
  --dart-define=OPENAI_API_KEY=tu_key \
  --dart-define=OPENAI_MODEL=gpt-5.5 \
  --dart-define=WEATHER_API_KEY=tu_key \
  --dart-define=GOOGLE_MAPS_API_KEY=tu_key
```

Firebase Auth/Firestore en produccion requiere:

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=tu_key \
  --dart-define=FIREBASE_APP_ID=tu_app_id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=sender_id \
  --dart-define=FIREBASE_PROJECT_ID=project_id \
  --dart-define=FIREBASE_AUTH_DOMAIN=project.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=project.appspot.com
```

Si no hay configuracion Firebase, la app entra en modo desarrollo local para permitir pruebas sin guardar datos reales. En produccion, Auth y Firestore se usan para `users/{userId}` y subcolecciones privadas.

Reglas de seguridad: ver `firestore.rules`.

Para Android, Google Maps tambien lee el placeholder nativo desde Gradle. Ejecuta con:

```bash
flutter run -PGOOGLE_MAPS_API_KEY=tu_key \
  --dart-define=OPENAI_API_KEY=tu_key \
  --dart-define=OPENAI_MODEL=gpt-5.5 \
  --dart-define=WEATHER_API_KEY=tu_key \
  --dart-define=GOOGLE_MAPS_API_KEY=tu_key
```

En iOS, configura `GOOGLE_MAPS_API_KEY` como build setting o variable de entorno de Xcode para llenar `GoogleMapsApiKey` en `Info.plist`.

## Permisos

Android:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `INTERNET`
- API key de Google Maps en `AndroidManifest.xml` via `GOOGLE_MAPS_API_KEY`.

iOS:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `GoogleMapsApiKey` en `Info.plist`.

La app solicita permiso de ubicacion en tiempo de ejecucion, obtiene latitud, longitud, ciudad y precision, y muestra estados de loading/error cuando el permiso es denegado.

## Siguiente fase

Conectar implementaciones reales para:

- Firebase Authentication, Firestore y Storage.
- API de indice KP/clima espacial.
- APIs oficiales de zonas, restricciones, aeropuertos, helipuertos y NOTAM.

## Nota legal

Aura Drones IA es una herramienta de apoyo. Antes de volar, el piloto debe confirmar normativa local, restricciones vigentes, permisos, NOTAM y condiciones reales.
