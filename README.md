# Aura Drones IA

App Flutter premium para pilotos de drones, creadores de contenido aereo y vuelos mas seguros.

## Incluye

- Arquitectura modular en `lib/core` y `lib/features`.
- Material 3, tema oscuro glassmorphism y componentes reutilizables.
- Navegacion completa con GoRouter.
- Estado con Riverpod.
- Home Dashboard, clima, Fly Score, Aura IA, mapa, drones, baterias, planeador, academia, historial, perfil y ajustes.
- Ubicacion real con `geolocator` y `geocoding`, con permisos Android/iOS y manejo de errores.
- Clima real gratuito con Open-Meteo, sin API key.
- Aura IA Local con reglas internas y contexto real de clima, ubicacion, KP, Fly Score, dron, bateria, checklist y objetivo del piloto.
- Aura Space Weather Engine con comparacion multi-fuente gratuita para KP y confianza.
- Mapa gratuito con Flutter Map + OpenStreetMap, ubicacion actual y capas preparadas para zonas/NOTAM.
- Cero costo operativo para clima, mapa e IA: sin Google Maps, sin OpenWeather, sin OpenAI y sin Gemini.

## Ejecutar

```bash
flutter pub get
flutter run
```

Firebase Auth y Firestore usan `lib/firebase_options.dart`, generado por FlutterFire. En produccion, Auth y Firestore guardan datos en `users/{userId}` y subcolecciones privadas.

Reglas de seguridad: ver `firestore.rules`.

El clima usa Open-Meteo y el mapa usa tiles publicos de OpenStreetMap mediante `flutter_map`; no requieren API keys, tarjeta bancaria ni SDK nativo de Google Maps.

Aura IA funciona localmente con reglas internas y datos reales disponibles en el dispositivo. No llama a OpenAI, Gemini ni otros servicios de IA de pago.

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
