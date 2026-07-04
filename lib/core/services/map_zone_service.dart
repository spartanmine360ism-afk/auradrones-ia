import 'package:latlong2/latlong.dart';

import '../models/location_snapshot.dart';
import '../models/map_zone.dart';

abstract class MapZoneService {
  Future<List<MapZone>> zonesNear(LocationSnapshot location);
  Future<bool> isRestricted(LocationSnapshot location);
}

class MockMapZoneService implements MapZoneService {
  @override
  Future<bool> isRestricted(LocationSnapshot location) async {
    final zones = await zonesNear(location);
    return zones.any(
      (zone) =>
          zone.type == MapZoneType.restricted ||
          zone.type == MapZoneType.airport,
    );
  }

  @override
  Future<List<MapZone>> zonesNear(LocationSnapshot location) async {
    final center = LatLng(location.latitude, location.longitude);
    return [
      MapZone(
        id: 'free-current',
        name: 'Zona libre cercana',
        type: MapZoneType.free,
        center: center,
        radiusMeters: 600,
        maxAltitudeMeters: 120,
        requiresPermission: false,
        recommendation: 'Vuela manteniendo linea visual y altura permitida.',
      ),
      MapZone(
        id: 'caution-urban',
        name: 'Area urbana densa',
        type: MapZoneType.caution,
        center: LatLng(location.latitude + .008, location.longitude + .006),
        radiusMeters: 450,
        maxAltitudeMeters: 60,
        requiresPermission: false,
        recommendation: 'Evita volar sobre personas y revisa privacidad.',
      ),
      MapZone(
        id: 'notam-placeholder',
        name: 'Capa NOTAM preparada',
        type: MapZoneType.notam,
        center: LatLng(location.latitude - .006, location.longitude - .007),
        radiusMeters: 350,
        maxAltitudeMeters: 0,
        requiresPermission: true,
        recommendation:
            'Conecta proveedor NOTAM oficial antes de operacion comercial.',
      ),
    ];
  }
}
