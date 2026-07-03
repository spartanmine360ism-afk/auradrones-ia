import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/flight_log.dart';
import '../../core/models/weather_snapshot.dart';
import '../../core/models/kp_index.dart';
import '../../core/models/fly_score.dart';
import '../../core/models/drone.dart';
import '../../core/models/battery.dart';
import '../../core/models/location_snapshot.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';
import '../shared/metric_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de vuelos')),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  const MetricTile(
                    icon: Icons.flight_takeoff,
                    label: 'Vuelos',
                    value: 'Dato no disponible',
                  ),
                  MetricTile(
                    icon: Icons.timer_outlined,
                    label: 'Horas',
                    value: profile?.totalFlightHours.toStringAsFixed(1) ?? '0',
                  ),
                  const MetricTile(
                    icon: Icons.speed,
                    label: 'Mejor score',
                    value: 'Dato no disponible',
                  ),
                  const MetricTile(
                    icon: Icons.location_on_outlined,
                    label: 'Frecuente',
                    value: 'Dato no disponible',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuraGlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Registrar vuelo anterior'),
                  subtitle: const Text(
                    'Guarda fecha, ubicacion, dron, bateria, clima y aprendizajes.',
                  ),
                  onTap: () => _showFlightForm(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFlightForm(BuildContext context, WidgetRef ref) async {
    final location = TextEditingController();
    final duration = TextEditingController();
    final type = TextEditingController(text: 'Video');
    final notes = TextEditingController();
    final problems = TextEditingController();
    final learnings = TextEditingController();
    final weather = await _tryFuture<WeatherSnapshot>(
      ref.read(weatherProvider.future),
    );
    final kp = await _tryFuture<KpIndex>(ref.read(kpProvider.future));
    final score = await _tryFuture<FlyScore>(ref.read(flyScoreProvider.future));
    final drone = await _tryFuture<Drone>(ref.read(activeDroneProvider.future));
    final battery = await _tryFuture<DroneBattery>(
      ref.read(activeBatteryProvider.future),
    );
    final currentLocation = await _tryFuture<LocationSnapshot>(
      ref.read(locationProvider.future),
    );

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registrar vuelo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                controller: location,
                decoration: InputDecoration(
                  labelText: 'Ubicacion',
                  hintText: currentLocation?.city,
                ),
              ),
              TextField(
                controller: duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duracion min'),
              ),
              TextField(
                controller: type,
                decoration: const InputDecoration(labelText: 'Tipo de vuelo'),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notas'),
              ),
              TextField(
                controller: problems,
                decoration: const InputDecoration(labelText: 'Problemas'),
              ),
              TextField(
                controller: learnings,
                decoration: const InputDecoration(labelText: 'Aprendizajes'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  await ref
                      .read(userDataServiceProvider)
                      .saveFlight(
                        user.id,
                        FlightLog(
                          id: '',
                          date: DateTime.now(),
                          location: location.text.trim().isEmpty
                              ? currentLocation?.city ?? ''
                              : location.text.trim(),
                          coordinates: currentLocation?.coordinates ?? '',
                          droneId: drone?.id ?? '',
                          batteryId: battery?.id ?? '',
                          durationMinutes: int.tryParse(duration.text) ?? 0,
                          flightType: type.text.trim(),
                          weather: weather == null
                              ? 'dato no disponible'
                              : '${weather.temperatureC.round()} C, viento ${weather.windKmh.round()} km/h',
                          kp: kp?.value ?? 0,
                          flyScore: score?.value ?? 0,
                          notes: notes.text.trim(),
                          problems: problems.text.trim(),
                          learnings: learnings.text.trim(),
                          mediaUrls: const [],
                        ),
                      );
                  await ref
                      .read(userDataServiceProvider)
                      .addFlightHours(
                        user.id,
                        (int.tryParse(duration.text) ?? 0) / 60,
                      );
                  ref.invalidate(userProfileProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar vuelo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<T?> _tryFuture<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }
}
