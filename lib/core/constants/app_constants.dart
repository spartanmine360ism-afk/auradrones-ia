class AppConstants {
  const AppConstants._();

  /// Nombre de la aplicación
  static const appName = 'Aura Drones IA';

  /// Google Gemini
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// OpenWeather
  static const weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
  );

  /// Google Maps
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
}