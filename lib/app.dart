import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/aura_theme.dart';

class AuraDronesApp extends StatelessWidget {
  const AuraDronesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aura Drones IA',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
