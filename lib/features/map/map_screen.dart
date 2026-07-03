import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/map_zone.dart';
import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (AppConstants.googleMapsApiKey.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: AuraGlassCard(
                      child: Text(
                        'Google Maps esta integrado. Agrega GOOGLE_MAPS_API_KEY para cargar mapas reales en Android/iOS/Web.',
                      ),
                    ),
                  ),
                AuraGlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 420,
                      child: zones.when(
                        data: (items) => GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(current.latitude, current.longitude),
                            zoom: 14,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          markers: _markers(items),
                          circles: _circles(items),
                          onTap: (_) {},
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

  Set<Marker> _markers(List<MapZone> zones) {
    return zones
        .map(
          (zone) => Marker(
            markerId: MarkerId(zone.id),
            position: zone.center,
            infoWindow: InfoWindow(
              title: zone.name,
              snippet: '${zone.label} - ${zone.recommendation}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(zone.type)),
          ),
        )
        .toSet();
  }

  Set<Circle> _circles(List<MapZone> zones) {
    return zones
        .map(
          (zone) => Circle(
            circleId: CircleId(zone.id),
            center: zone.center,
            radius: zone.radiusMeters,
            fillColor: zone.color.withValues(alpha: .16),
            strokeColor: zone.color,
            strokeWidth: 2,
          ),
        )
        .toSet();
  }

  double _markerHue(MapZoneType type) {
    return switch (type) {
      MapZoneType.free => BitmapDescriptor.hueGreen,
      MapZoneType.caution ||
      MapZoneType.heliport ||
      MapZoneType.notam => BitmapDescriptor.hueYellow,
      MapZoneType.restricted || MapZoneType.airport => BitmapDescriptor.hueRed,
    };
  }
}
