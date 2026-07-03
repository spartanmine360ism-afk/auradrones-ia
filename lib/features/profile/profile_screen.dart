import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              ref.invalidateSensitiveUserState();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AuraBackground(
        child: SafeArea(
          child: profile.when(
            data: (value) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                AuraGlassCard(
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 36, child: Icon(Icons.person)),
                      const SizedBox(height: 10),
                      Text(
                        value?.name ?? 'Piloto',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${value?.pilotLevel ?? ''} - ${value?.mainGoal ?? ''}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AuraGlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: Text(value?.email ?? ''),
                      ),
                      ListTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: const Text('Horas totales de vuelo'),
                        trailing: Text(
                          '${value?.totalFlightHours.toStringAsFixed(1) ?? '0'} h',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.add_alarm_outlined),
                        title: const Text('Registrar horas realizadas'),
                        onTap: () => _addHours(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
          ),
        ),
      ),
    );
  }

  Future<void> _addHours(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar horas'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Horas'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref
                    .read(userDataServiceProvider)
                    .addFlightHours(
                      user.id,
                      double.tryParse(controller.text) ?? 0,
                    );
                ref.invalidate(userProfileProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
