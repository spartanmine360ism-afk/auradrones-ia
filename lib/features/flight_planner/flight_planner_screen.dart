import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class FlightPlannerScreen extends ConsumerWidget {
  const FlightPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(flightPlanProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planear vuelo'),
        actions: [
          IconButton(
            tooltip: 'Drones',
            onPressed: () => context.go('/drones'),
            icon: const Icon(Icons.flight),
          ),
          IconButton(
            tooltip: 'Baterias',
            onPressed: () => context.go('/batteries'),
            icon: const Icon(Icons.battery_5_bar),
          ),
        ],
      ),
      body: AuraBackground(
        child: SafeArea(
          child: plan.when(
            data: (p) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AuraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('${p.location} - ${p.time} - ${p.type}'),
                      const SizedBox(height: 8),
                      Text('${p.drone} - ${p.estimatedMinutes} min estimados'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Shotlist sugerida',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                for (final shot in p.shots) ...[
                  AuraGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shot.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(shot.description),
                        const SizedBox(height: 8),
                        Text(
                          'Dificultad ${shot.difficulty} - Riesgo ${shot.risk}',
                        ),
                        Text(shot.camera),
                        const SizedBox(height: 6),
                        Text(shot.tip),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AuraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checklist previa',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final item in const [
                        'Helices revisadas',
                        'Baterias cargadas',
                        'Clima y KP revisados',
                        'Zona y permisos revisados',
                        'Home Point actualizado',
                        'Plan de emergencia listo',
                      ])
                        CheckboxListTile(
                          value: true,
                          onChanged: (_) {},
                          title: Text(item),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}
