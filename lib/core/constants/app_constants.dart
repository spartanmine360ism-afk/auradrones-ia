class AppConstants {
  const AppConstants._();

  static const appName = 'Aura Drones IA';
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  static const weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static bool get hasFirebaseConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty;

  static List<String> get missingFirebaseConfigKeys {
    return [
      if (firebaseApiKey.isEmpty) 'FIREBASE_API_KEY',
      if (firebaseAppId.isEmpty) 'FIREBASE_APP_ID',
      if (firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
      if (firebaseMessagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    ];
  }
}
