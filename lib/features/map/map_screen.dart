import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/location_snapshot.dart';
import '../../core/models/map_zone.dart';
import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  double _zoom = 14;

  void _centerOn(LocationSnapshot location) {
    final center = LatLng(location.latitude, location.longitude);
    _mapController.move(center, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final zones = ref.watch(mapZonesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa y zonas')),
      body: AuraBackground(
        child: SafeArea(
          child: location.when(
            data: (current) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AuraGlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 420,
                      child: zones.when(
                        data: (items) => _OpenStreetMapView(
                          controller: _mapController,
                          location: current,
                          zones: items,
                          zoom: _zoom,
                          onPositionChanged: (zoom) => _zoom = zoom,
                          onCenter: () => _centerOn(current),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(
                          child: Text('No se pudieron cargar zonas: $error'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AuraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coordenadas: ${current.coordinates}'),
                      Text(
                        'Precision GPS: ${current.accuracyMeters.round()} m',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                zones.when(
                  data: (items) => Column(
                    children: [
                      for (final zone in items) ...[
                        AuraGlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.circle,
                              color: zone.color,
                              size: 16,
                            ),
                            title: Text(zone.name),
                            subtitle: Text(
                              '${zone.label} - altura max ${zone.maxAltitudeMeters} m\n${zone.recommendation}',
                            ),
                            trailing: Text(
                              zone.requiresPermission
                                  ? 'Permiso'
                                  : 'Sin permiso',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const AuraGlassCard(
                  child: Text(
                    'Capas listas para conectar: zonas restringidas, aeropuertos, helipuertos, areas urbanas densas, parques nacionales, zonas temporales y NOTAM.',
                  ),
                ),
                const SizedBox(height: 12),
                const AuraGlassCard(
                  child: Text(
                    'Antes de volar, confirma la normativa local vigente. Esta app es una herramienta de apoyo, no reemplaza la responsabilidad del piloto.',
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AuraGlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_off_outlined,
                      color: AuraColors.amber,
                    ),
                    title: const Text('Activa ubicacion para ver el mapa'),
                    subtitle: Text('$error'),
                    trailing: IconButton(
                      tooltip: 'Reintentar',
                      onPressed: () => ref.invalidate(locationProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenStreetMapView extends StatelessWidget {
  const _OpenStreetMapView({
    required this.controller,
    required this.location,
    required this.zones,
    required this.zoom,
    required this.onPositionChanged,
    required this.onCenter,
  });

  final MapController controller;
  final LocationSnapshot location;
  final List<MapZone> zones;
  final double zoom;
  final ValueChanged<double> onPositionChanged;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    final pilot = LatLng(location.latitude, location.longitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: pilot,
            initialZoom: zoom,
            minZoom: 3,
            maxZoom: 18,
            onPositionChanged: (position, _) {
              onPositionChanged(position.zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.aurapilot.aura_drones_ia',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: pilot,
                  radius: location.accuracyMeters.clamp(10, 250),
                  useRadiusInMeter: true,
                  color: AuraColors.cyan.withValues(alpha: .14),
                  borderColor: AuraColors.cyan,
                  borderStrokeWidth: 2,
                ),
                for (final zone in zones)
                  CircleMarker(
                    point: zone.center,
                    radius: zone.radiusMeters,
                    useRadiusInMeter: true,
                    color: zone.color.withValues(alpha: .13),
                    borderColor: zone.color,
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pilot,
                  width: 54,
                  height: 54,
                  child: const _PilotMarker(),
                ),
                for (final zone in zones)
                  Marker(
                    point: zone.center,
                    width: 44,
                    height: 44,
                    child: _ZoneMarker(zone: zone),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          top: 12,
          child: FloatingActionButton.small(
            heroTag: 'center-map',
            tooltip: 'Centrar ubicacion',
            onPressed: onCenter,
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xE6121726),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                location.coordinates,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PilotMarker extends StatelessWidget {
  const _PilotMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AuraColors.cyan,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AuraColors.cyan.withValues(alpha: .35),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Icon(Icons.person_pin_circle, color: Colors.black87),
    );
  }
}

class _ZoneMarker extends StatelessWidget {
  const _ZoneMarker({required this.zone});

  final MapZone zone;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: zone.name,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: zone.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(_iconFor(zone.type), color: Colors.black87, size: 20),
      ),
    );
  }

  IconData _iconFor(MapZoneType type) {
    return switch (type) {
      MapZoneType.free => Icons.check,
      MapZoneType.caution => Icons.priority_high,
      MapZoneType.restricted => Icons.block,
      MapZoneType.airport => Icons.flight_takeoff,
      MapZoneType.heliport => Icons.local_hospital,
      MapZoneType.notam => Icons.campaign,
    };
  }
}
