import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool initialized = false;
  static Object? initializationError;

  static bool get configured => true;

  static bool get localMode => false;

  static bool get failed => initializationError != null;

  static String? get failureMessage => initializationError?.toString();

  static String get localModeMessage => '';

  static Future<void> initialize() async {
    if (initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      initialized = true;
      initializationError = null;

      debugPrint('Firebase inicializado correctamente');
    } catch (error, stackTrace) {
      initialized = false;
      initializationError = error;

      debugPrint('Error inicializando Firebase');
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
    }
  }
}
