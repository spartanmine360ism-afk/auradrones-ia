import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';
import '../shared/metric_tile.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final location = ref.watch(locationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Clima para vuelo')),
      body: AuraBackground(
        child: SafeArea(
          child: weather.when(
            data: (w) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                location.when(
                  data: (value) => AuraGlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.my_location),
                      title: Text(value.city),
                      subtitle: Text(
                        '${value.coordinates} - precision ${value.accuracyMeters.round()} m',
                      ),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => AuraGlassCard(
                    child: Text('No se pudo obtener ubicacion: $error'),
                  ),
                ),
                const SizedBox(height: 14),
                AuraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.city,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('Coordenadas ${w.coordinates}'),
                      const SizedBox(height: 14),
                      Text(
                        'Viento de ${w.windKmh.round()} km/h con rachas de ${w.gustKmh.round()} km/h. Bueno para drones medianos; con drones ligeros, manten altura moderada y regreso con bateria amplia.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 620
                      ? 4
                      : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: .95,
                  children: [
                    MetricTile(
                      icon: Icons.thermostat,
                      label: 'Temperatura',
                      value: '${w.temperatureC.round()} C',
                      caption: 'Sensacion ${w.feelsLikeC.round()} C',
                    ),
                    MetricTile(
                      icon: Icons.air,
                      label: 'Direccion',
                      value: w.windDirection,
                      caption: '${w.windKmh.round()} km/h',
                    ),
                    MetricTile(
                      icon: Icons.visibility,
                      label: 'Visibilidad',
                      value: '${w.visibilityKm} km',
                    ),
                    MetricTile(
                      icon: Icons.cloud,
                      label: 'Nubosidad',
                      value: '${w.cloudCover}%',
                    ),
                    MetricTile(
                      icon: Icons.water_drop,
                      label: 'Lluvia',
                      value: '${w.rainChance}%',
                    ),
                    MetricTile(
                      icon: Icons.wb_twilight,
                      label: 'Luz',
                      value: w.sunset,
                      caption: 'Amanecer ${w.sunrise}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AuraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pronostico por hora',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final hour in w.hourly)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(hour.time),
                          subtitle: Text(
                            '${hour.tempC.round()} C, viento ${hour.windKmh.round()} km/h',
                          ),
                          trailing: Text('${hour.rainChance}% lluvia'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('No se pudo cargar clima: $error')),
          ),
        ),
      ),
    );
  }
}
