import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/battery.dart';
import '../models/drone.dart';
import '../models/flight_log.dart';
import '../models/fly_score.dart';
import '../models/kp_index.dart';
import '../models/lesson.dart';
import '../models/location_snapshot.dart';
import '../models/map_zone.dart';
import '../models/auth_user.dart';
import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';
import 'auth_service.dart';
import 'fly_score_service.dart';
import 'location_service.dart';
import 'local_ai_service.dart';
import 'map_zone_service.dart';
import 'mock_data.dart';
import 'kp_index_service.dart';
import 'user_data_service.dart';
import 'weather_service.dart';

final userDataServiceProvider = Provider<UserDataService>(
  (ref) => FirestoreUserDataService(),
);
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(ref.watch(userDataServiceProvider)),
);
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);
final currentUserProvider = Provider<AuthUser?>((ref) {
  final streamUser = ref.watch(authStateProvider).value;
  return streamUser ?? ref.watch(authServiceProvider).currentUser;
});
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(userDataServiceProvider).watchProfile(user.id);
});

extension SensitiveUserStateInvalidation on WidgetRef {
  void invalidateSensitiveUserState() {
    invalidate(userProfileProvider);
    invalidate(dronesProvider);
    invalidate(batteriesProvider);
    invalidate(activeDroneProvider);
    invalidate(activeBatteryProvider);
    invalidate(flyScoreProvider);
    invalidate(weatherProvider);
    invalidate(locationProvider);
    invalidate(mapZonesProvider);
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);
final weatherServiceProvider = Provider<WeatherService>(
  (ref) => WeatherApiService(),
);
final kpIndexServiceProvider = Provider<KpIndexService>(
  (ref) => NoaaKpIndexService(),
);
final droneServiceProvider = Provider<DroneService>(
  (ref) => UserDroneService(ref),
);
final batteryServiceProvider = Provider<BatteryService>(
  (ref) => UserBatteryService(ref),
);
final academyServiceProvider = Provider<AcademyService>(
  (ref) => MockAcademyService(),
);
final localAiServiceProvider = Provider<AiService>((ref) => LocalAiService());
final mapZoneServiceProvider = Provider<MapZoneService>(
  (ref) => MockMapZoneService(),
);

final locationProvider = FutureProvider<LocationSnapshot>(
  (ref) => ref.watch(locationServiceProvider).current(),
);
final weatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final location = await ref.watch(locationProvider.future);
  return ref.watch(weatherServiceProvider).current(location);
});
final kpProvider = FutureProvider<KpIndex>(
  (ref) => ref.watch(kpIndexServiceProvider).current(),
);
final dronesProvider = FutureProvider<List<Drone>>(
  (ref) => ref.watch(droneServiceProvider).all(),
);
final batteriesProvider = FutureProvider<List<DroneBattery>>(
  (ref) => ref.watch(batteryServiceProvider).all(),
);
final flightLogsProvider = StreamProvider<List<FlightLog>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(userDataServiceProvider).watchFlights(user.id);
});
final activeDroneProvider = FutureProvider<Drone>((ref) async {
  final drones = await ref.watch(dronesProvider.future);
  if (drones.isEmpty) {
    throw StateError('Agrega un dron para calcular Fly Score.');
  }
  final profile = ref.watch(userProfileProvider).value;
  return drones.firstWhere(
    (drone) => drone.id == profile?.activeDroneId,
    orElse: () => drones.first,
  );
});
final activeBatteryProvider = FutureProvider<DroneBattery>((ref) async {
  final batteries = await ref.watch(batteriesProvider.future);
  if (batteries.isEmpty) {
    throw StateError('Agrega una bateria para calcular Fly Score.');
  }
  final profile = ref.watch(userProfileProvider).value;
  return batteries.firstWhere(
    (battery) => battery.id == profile?.activeBatteryId,
    orElse: () => batteries.first,
  );
});
final lessonsProvider = FutureProvider<List<Lesson>>(
  (ref) => ref.watch(academyServiceProvider).featured(),
);
final mapZonesProvider = FutureProvider<List<MapZone>>((ref) async {
  final location = await ref.watch(locationProvider.future);
  return ref.watch(mapZoneServiceProvider).zonesNear(location);
});

final flyScoreProvider = FutureProvider<FlyScore>((ref) async {
  final weather = await ref.watch(weatherProvider.future);
  final kp = await ref.watch(kpProvider.future);
  final location = await ref.watch(locationProvider.future);
  final battery = await ref.watch(activeBatteryProvider.future);
  final drone = await ref.watch(activeDroneProvider.future);
  final isRestricted = await ref
      .watch(mapZoneServiceProvider)
      .isRestricted(location);
  return FlyScoreService().calculate(
    weather: weather,
    kp: kp,
    location: location,
    batteryLevel: battery.level,
    isRestrictedZone: isRestricted,
    pilotLevel:
        ref.watch(userProfileProvider).value?.pilotLevel ??
        'Dato no disponible',
    droneType: drone.type,
  );
});

abstract class DroneService {
  Future<List<Drone>> all();
}

abstract class BatteryService {
  Future<List<DroneBattery>> all();
}

abstract class AcademyService {
  Future<List<Lesson>> featured();
}

class UserDroneService implements DroneService {
  UserDroneService(this.ref);

  final Ref ref;

  @override
  Future<List<Drone>> all() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final stream = ref.watch(userDataServiceProvider).watchDrones(user.id);
    return stream.first;
  }
}

class UserBatteryService implements BatteryService {
  UserBatteryService(this.ref);

  final Ref ref;

  @override
  Future<List<DroneBattery>> all() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final stream = ref.watch(userDataServiceProvider).watchBatteries(user.id);
    return stream.first;
  }
}

class MockAcademyService implements AcademyService {
  @override
  Future<List<Lesson>> featured() async => MockData.lessons;
}
