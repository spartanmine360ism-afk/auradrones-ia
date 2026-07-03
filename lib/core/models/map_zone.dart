import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapZoneType { free, caution, restricted, airport, heliport, notam }

class MapZone {
  const MapZone({
    required this.id,
    required this.name,
    required this.type,
    required this.center,
    required this.radiusMeters,
    required this.maxAltitudeMeters,
    required this.requiresPermission,
    required this.recommendation,
  });

  final String id;
  final String name;
  final MapZoneType type;
  final LatLng center;
  final double radiusMeters;
  final int maxAltitudeMeters;
  final bool requiresPermission;
  final String recommendation;

  Color get color {
    return switch (type) {
      MapZoneType.free => const Color(0xFF55F0B4),
      MapZoneType.caution ||
      MapZoneType.heliport ||
      MapZoneType.notam => const Color(0xFFFFC857),
      MapZoneType.restricted || MapZoneType.airport => const Color(0xFFFF5A6C),
    };
  }

  String get label {
    return switch (type) {
      MapZoneType.free => 'Permitido',
      MapZoneType.caution => 'Precaucion',
      MapZoneType.restricted => 'Restringido',
      MapZoneType.airport => 'Aeropuerto',
      MapZoneType.heliport => 'Helipuerto',
      MapZoneType.notam => 'NOTAM',
    };
  }
}
