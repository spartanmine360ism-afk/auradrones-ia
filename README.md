# Aura Drones IA

App Flutter premium para pilotos de drones, creadores de contenido aereo y vuelos mas seguros.

## Incluye

- Arquitectura modular en `lib/core` y `lib/features`.
- Material 3, tema oscuro glassmorphism y componentes reutilizables.
- Navegacion completa con GoRouter.
- Estado con Riverpod.
- Home Dashboard, clima, Fly Score, Aura IA, mapa, drones, baterias, planeador, academia, historial, perfil y ajustes.
- Ubicacion real con `geolocator` y `geocoding`, con permisos Android/iOS y manejo de errores.
- Clima real con OpenWeather usando `WEATHER_API_KEY`.
- Aura IA Local con reglas internas y contexto real de clima, ubicacion, KP, Fly Score, dron, bateria, checklist y objetivo del piloto.
- Mapa gratuito con Flutter Map + OpenStreetMap, ubicacion actual y capas preparadas para zonas/NOTAM.
- API keys por `--dart-define`, sin secretos en el codigo.

## Ejecutar

```bash
flutter pub get
flutter run \
  --dart-define=WEATHER_API_KEY=tu_key
```

Firebase Auth y Firestore usan `lib/firebase_options.dart`, generado por FlutterFire. En produccion, Auth y Firestore guardan datos en `users/{userId}` y subcolecciones privadas.

Reglas de seguridad: ver `firestore.rules`.

El mapa usa tiles publicos de OpenStreetMap mediante `flutter_map`; no requiere API key ni SDK nativo de Google Maps.

## Permisos

Android:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `INTERNET`

iOS:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

La app solicita permiso de ubicacion en tiempo de ejecucion, obtiene latitud, longitud, ciudad y precision, y muestra estados de loading/error cuando el permiso es denegado.

## Nota legal

Aura Drones IA es una herramienta de apoyo. Antes de volar, el piloto debe confirmar normativa local, restricciones vigentes, permisos, NOTAM y condiciones reales.
