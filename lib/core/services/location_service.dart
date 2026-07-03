import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_snapshot.dart';

abstract class LocationService {
  Future<LocationSnapshot> current();
}

class LocationPermissionException implements Exception {
  const LocationPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationSnapshot> current() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionException(
        'Activa los servicios de ubicacion para calcular clima y Fly Score.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException(
        'Permiso de ubicacion denegado. Puedes activarlo desde ajustes.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'Permiso de ubicacion bloqueado. Abre ajustes del sistema para permitirlo.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final city = await _resolveCity(position.latitude, position.longitude);
    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      accuracyMeters: position.accuracy,
      isMocked: position.isMocked,
    );
  }

  Future<String> _resolveCity(double latitude, double longitude) async {
    try {
      final places = await placemarkFromCoordinates(latitude, longitude);
      if (places.isEmpty) return 'Ubicacion actual';
      final place = places.first;
      return [
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((value) => value != null && value.trim().isNotEmpty).join(', ');
    } catch (_) {
      return 'Ubicacion actual';
    }
  }
}

class MockLocationService implements LocationService {
  @override
  Future<LocationSnapshot> current() async {
    return const LocationSnapshot(
      latitude: 19.4326,
      longitude: -99.1332,
      city: 'Ciudad de Mexico',
      accuracyMeters: 35,
      isMocked: true,
    );
  }
}
