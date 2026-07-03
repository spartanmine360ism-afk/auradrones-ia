import 'package:firebase_core/firebase_core.dart';

import 'core/constants/app_constants.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static bool get isConfigured => AppConstants.hasFirebaseConfig;

  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: AppConstants.firebaseApiKey,
      appId: AppConstants.firebaseAppId,
      messagingSenderId: AppConstants.firebaseMessagingSenderId,
      projectId: AppConstants.firebaseProjectId,
      authDomain: AppConstants.firebaseAuthDomain,
      storageBucket: AppConstants.firebaseStorageBucket,
    );
  }
}
