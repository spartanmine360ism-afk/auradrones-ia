import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool initialized = false;
  static Object? initializationError;

  static bool get configured => DefaultFirebaseOptions.isConfigured;
  static bool get localMode => !configured;
  static bool get failed =>
      configured && !initialized && initializationError != null;
  static String? get failureMessage => initializationError?.toString();

  static Future<void> initialize() async {
    if (!configured) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      initialized = true;
      initializationError = null;
    } catch (error) {
      initialized = false;
      initializationError = error;
      debugPrint('Firebase disabled: $error');
    }
  }
}
