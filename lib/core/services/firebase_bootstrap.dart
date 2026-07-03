import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool initialized = false;

  static Future<void> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      initialized = true;
    } catch (error) {
      initialized = false;
      debugPrint('Firebase disabled: $error');
    }
  }
}
