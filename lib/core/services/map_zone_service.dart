import '../models/location_snapshot.dart';
import '../models/map_zone.dart';

abstract class MapZoneService {
  Future<List<MapZone>> zonesNear(LocationSnapshot location);
  Future<bool> isRestricted(LocationSnapshot location);
}

class EmptyMapZoneService implements MapZoneService {
  @override
  Future<bool> isRestricted(LocationSnapshot location) async => false;

  @override
  Future<List<MapZone>> zonesNear(LocationSnapshot location) async => const [];
}
