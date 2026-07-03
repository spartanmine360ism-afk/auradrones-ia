import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/fly_score.dart';
import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';
import '../../core/widgets/aura_status_badge.dart';
import '../shared/section_title.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final score = ref.watch(flyScoreProvider);
    final kp = ref.watch(kpProvider);
    final location = ref.watch(locationProvider);
    final battery = ref.watch(activeBatteryProvider);
    final width = MediaQuery.sizeOf(context).width;
    final padding = width <= 430 ? 12.0 : 18.0;

    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(padding, 10, padding, 22),
            children: [
              Text(
                'Hola, ${AppConstants.pilotName} - Aura Pilot',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              score.when(
                data: (value) => _FlyScoreHero(
                  score: value,
                  onTap: () => context.go('/score'),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => AuraGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Text('Fly Score pendiente\n$error'),
                ),
              ),
              const SizedBox(height: 10),
              weather.when(
                data: (w) => _CompactMetricCard(
                  icon: Icons.air,
                  title: 'Viento / rachas',
                  value: '${w.windKmh.round()} / ${w.gustKmh.round()} km/h',
                  details: [
                    'Lluvia ${w.rainChance}%',
                    'Visibilidad ${w.visibilityKm.toStringAsFixed(1)} km',
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => AuraGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Text('Clima no disponible\n$error'),
                ),
              ),
              const SizedBox(height: 10),
              kp.when(
                data: (value) => _CompactMetricCard(
                  icon: Icons.satellite_alt_outlined,
                  title: 'KP',
                  value: value.value.toStringAsFixed(1),
                  details: [value.risk],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const _CompactMetricCard(
                  icon: Icons.satellite_alt_outlined,
                  title: 'KP',
                  value: 'Dato no disponible',
                  details: ['Revisa antes de volar'],
                ),
              ),
              const SizedBox(height: 10),
              battery.when(
                data: (value) => _CompactMetricCard(
                  icon: Icons.battery_5_bar,
                  title: 'Bateria',
                  value: '${value.level}%',
                  details: ['Salud ${value.health}%', value.status],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const _CompactMetricCard(
                  icon: Icons.battery_5_bar,
                  title: 'Bateria',
                  value: 'Dato no disponible',
                  details: ['No se pudo leer bateria'],
                ),
              ),
              const SizedBox(height: 10),
              location.when(
                data: (value) => _CompactMetricCard(
                  icon: Icons.my_location,
                  title: 'Ubicacion',
                  value: value.city,
                  details: [
                    value.coordinates,
                    'Precision ${value.accuracyMeters.round()} m',
                  ],
                ),
                loading: () => const _CompactMetricCard(
                  icon: Icons.my_location,
                  title: 'Ubicacion',
                  value: 'Obteniendo ubicacion',
                  details: ['Permite acceso en el telefono'],
                ),
                error: (error, _) => AuraGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_off_outlined,
                      color: AuraColors.amber,
                    ),
                    title: const Text('Ubicacion no disponible'),
                    subtitle: Text('$error'),
                    trailing: IconButton(
                      tooltip: 'Reintentar',
                      onPressed: () => ref.invalidate(locationProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Accesos rapidos'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAction('Clima', Icons.cloud_outlined, '/weather'),
                  _QuickAction('IA', Icons.auto_awesome, '/ai'),
                  _QuickAction('Mi dron', Icons.flight, '/drones'),
                  _QuickAction('Academia', Icons.school_outlined, '/academy'),
                  _QuickAction('Mapa', Icons.map_outlined, '/map'),
                  _QuickAction('Planear', Icons.route_outlined, '/planner'),
                ].map((item) => _QuickActionButton(item: item)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlyScoreHero extends StatelessWidget {
  const _FlyScoreHero({required this.score, required this.onTap});

  final FlyScore score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = score.value >= 80
        ? AuraColors.mint
        : score.value >= 60
        ? AuraColors.amber
        : AuraColors.danger;
    final factors = [
      ...score.positiveFactors.take(2),
      ...score.negativeFactors.take(1),
    ];

    return AuraGlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score.value / 100,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withValues(alpha: .08),
                  color: color,
                ),
                Text(
                  '${score.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuraStatusBadge(label: score.status, color: color),
                const SizedBox(height: 8),
                for (final factor in factors)
                  Text(
                    '- $factor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.25),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.details,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return AuraGlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AuraColors.cyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final detail in details)
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.item});

  final _QuickAction item;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => context.go(item.route),
      icon: Icon(item.icon, size: 17),
      label: Text(item.label),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
