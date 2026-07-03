import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final notifications =
        profile?.notifications ??
        const {
          'weather': true,
          'kp': true,
          'maintenance': true,
          'goldenHour': true,
        };

    Future<void> update(String key, bool value) async {
      if (profile == null) return;
      final updated = {...notifications, key: value};
      await ref
          .read(userDataServiceProvider)
          .saveProfile(profile.copyWith(notifications: updated));
      ref.invalidate(userProfileProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              AuraGlassCard(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: notifications['weather'] ?? true,
                      onChanged: (value) => update('weather', value),
                      title: const Text('Buen clima para volar'),
                      dense: true,
                    ),
                    SwitchListTile(
                      value: notifications['kp'] ?? true,
                      onChanged: (value) => update('kp', value),
                      title: const Text('Alertas de KP alto'),
                      dense: true,
                    ),
                    SwitchListTile(
                      value: notifications['maintenance'] ?? true,
                      onChanged: (value) => update('maintenance', value),
                      title: const Text('Mantenimiento y baterias'),
                      dense: true,
                    ),
                    SwitchListTile(
                      value: notifications['goldenHour'] ?? true,
                      onChanged: (value) => update('goldenHour', value),
                      title: const Text('Hora dorada proxima'),
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const AuraGlassCard(
                padding: EdgeInsets.all(12),
                child: Text(
                  'API keys por --dart-define. No se guardan en Firestore.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  ref.invalidateSensitiveUserState();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
