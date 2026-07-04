import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/drone_constants.dart';
import '../models/auth_user.dart';
import '../models/battery.dart';
import '../models/drone.dart';
import '../models/flight_log.dart';
import '../models/user_profile.dart';
import 'firebase_bootstrap.dart';
import 'mock_data.dart';

abstract class UserDataService {
  Stream<UserProfile?> watchProfile(String userId);
  Future<UserProfile> ensureUserProfile(AuthUser user);
  Future<void> saveProfile(UserProfile profile);
  Stream<List<Drone>> watchDrones(String userId);
  Future<void> saveDrone(String userId, Drone drone);
  Future<void> deleteDrone(String userId, String droneId);
  Stream<List<DroneBattery>> watchBatteries(String userId);
  Future<void> saveBattery(String userId, DroneBattery battery);
  Future<void> deleteBattery(String userId, String batteryId);
  Stream<List<FlightLog>> watchFlights(String userId);
  Future<void> saveFlight(String userId, FlightLog flight);
  Future<Map<String, bool>> loadPreflightChecklist(String userId);
  Future<void> savePreflightChecklist(String userId, Map<String, bool> values);
  Future<void> addFlightHours(String userId, double hours);
  Future<void> setActiveDrone(String userId, String? droneId);
  Future<void> setActiveBattery(String userId, String? batteryId);
}

UserProfile defaultProfileFor(AuthUser user) {
  return UserProfile(
    id: user.id,
    name: user.name,
    email: user.email,
    pilotLevel: 'Principiante',
    mainGoal: 'Hobby',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    totalFlightHours: 0,
    emailVerified: user.emailVerified,
    activeDroneId: null,
    activeBatteryId: null,
    notifications: const {
      'weather': true,
      'kp': true,
      'maintenance': true,
      'goldenHour': true,
    },
    onboardingComplete: false,
  );
}

class FirestoreUserDataService implements UserDataService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  StateError get _firebaseFailure => StateError(
    'Firebase esta configurado pero Firestore no pudo iniciar: ${FirebaseBootstrap.failureMessage}',
  );

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.watchProfile(userId);
    }
    if (FirebaseBootstrap.failed) return Stream.error(_firebaseFailure);
    return _users.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : UserProfile.fromMap(doc.id, data);
    });
  }

  @override
  Future<UserProfile> ensureUserProfile(AuthUser user) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.ensureUserProfile(user);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final ref = _users.doc(user.id);
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) {
      final profile = UserProfile.fromMap(doc.id, doc.data()!);
      if (profile.email != user.email ||
          profile.name != user.name ||
          profile.emailVerified != user.emailVerified) {
        final updated = profile.copyWith(
          name: user.name,
          email: user.email,
          emailVerified: user.emailVerified,
        );
        await ref.set(updated.toMap(), SetOptions(merge: true));
        return updated;
      }
      return profile;
    }
    final profile = defaultProfileFor(user);
    await ref.set(profile.toMap());
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.saveProfile(profile);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _users.doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<List<Drone>> watchDrones(String userId) {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.watchDrones(userId);
    }
    if (FirebaseBootstrap.failed) return Stream.error(_firebaseFailure);
    return _users.doc(userId).collection('drones').snapshots().asyncMap((
      snapshot,
    ) async {
      final drones = <Drone>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final drone = Drone.fromMap(doc.id, data);
        drones.add(drone);

        final savedType = data['type'] as String?;
        final savedStatus = data['status'] as String?;
        final rawType = savedType ?? data['tipo'] as String?;
        final rawStatus = savedStatus ?? data['estado'] as String?;
        final normalizedType = DroneConstants.normalizeDroneType(rawType);
        final normalizedStatus = DroneConstants.normalizeDroneStatus(rawStatus);

        if (savedType != normalizedType || savedStatus != normalizedStatus) {
          await doc.reference.set({
            'type': normalizedType,
            'status': normalizedStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      }
      return drones;
    });
  }

  @override
  Future<void> saveDrone(String userId, Drone drone) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.saveDrone(userId, drone);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final ref = drone.id.isEmpty
        ? _users.doc(userId).collection('drones').doc()
        : _users.doc(userId).collection('drones').doc(drone.id);
    await ref.set(
      drone
          .copyWith(
            id: ref.id,
            type: DroneConstants.normalizeDroneType(drone.type),
            status: DroneConstants.normalizeDroneStatus(drone.status),
            updatedAt: DateTime.now(),
          )
          .toMap(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteDrone(String userId, String droneId) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.deleteDrone(userId, droneId);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _users.doc(userId).collection('drones').doc(droneId).delete();
  }

  @override
  Stream<List<DroneBattery>> watchBatteries(String userId) {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.watchBatteries(userId);
    }
    if (FirebaseBootstrap.failed) return Stream.error(_firebaseFailure);
    return _users
        .doc(userId)
        .collection('batteries')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DroneBattery.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveBattery(String userId, DroneBattery battery) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.saveBattery(userId, battery);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final ref = battery.id.isEmpty
        ? _users.doc(userId).collection('batteries').doc()
        : _users.doc(userId).collection('batteries').doc(battery.id);
    await ref.set(
      battery.copyWith(id: ref.id, updatedAt: DateTime.now()).toMap(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteBattery(String userId, String batteryId) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.deleteBattery(userId, batteryId);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _users.doc(userId).collection('batteries').doc(batteryId).delete();
  }

  @override
  Stream<List<FlightLog>> watchFlights(String userId) {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.watchFlights(userId);
    }
    if (FirebaseBootstrap.failed) return Stream.error(_firebaseFailure);
    return _users.doc(userId).collection('flights').snapshots().map((snapshot) {
      final flights = snapshot.docs
          .map((doc) => FlightLog.fromMap(doc.id, doc.data()))
          .toList();
      flights.sort((a, b) => b.date.compareTo(a.date));
      return flights;
    });
  }

  @override
  Future<void> saveFlight(String userId, FlightLog flight) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.saveFlight(userId, flight);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final ref = flight.id.isEmpty
        ? _users.doc(userId).collection('flights').doc()
        : _users.doc(userId).collection('flights').doc(flight.id);
    await ref.set(flight.toMap(), SetOptions(merge: true));
  }

  @override
  Future<Map<String, bool>> loadPreflightChecklist(String userId) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.loadPreflightChecklist(userId);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final doc = await _users
        .doc(userId)
        .collection('flightState')
        .doc('preflight')
        .get();
    final data = doc.data()?['items'] as Map<String, dynamic>?;
    return data?.map((key, value) => MapEntry(key, value == true)) ?? {};
  }

  @override
  Future<void> savePreflightChecklist(
    String userId,
    Map<String, bool> values,
  ) async {
    if (FirebaseBootstrap.localMode) {
      return DevUserDataService.instance.savePreflightChecklist(userId, values);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _users.doc(userId).collection('flightState').doc('preflight').set({
      'items': values,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> addFlightHours(String userId, double hours) async {
    final profile = await ensureUserProfile(
      AuthUser(id: userId, email: '', name: '', emailVerified: true),
    );
    await saveProfile(
      profile.copyWith(totalFlightHours: profile.totalFlightHours + hours),
    );
  }

  @override
  Future<void> setActiveDrone(String userId, String? droneId) async {
    final profile = await ensureUserProfile(
      AuthUser(id: userId, email: '', name: '', emailVerified: true),
    );
    await saveProfile(profile.copyWith(activeDroneId: droneId));
  }

  @override
  Future<void> setActiveBattery(String userId, String? batteryId) async {
    final profile = await ensureUserProfile(
      AuthUser(id: userId, email: '', name: '', emailVerified: true),
    );
    await saveProfile(profile.copyWith(activeBatteryId: batteryId));
  }
}

class DevUserDataService implements UserDataService {
  DevUserDataService._();

  static final instance = DevUserDataService._();
  UserProfile? _profile;
  final _drones = [...MockData.drones];
  final _batteries = [...MockData.batteries];
  final _flights = <FlightLog>[];
  Map<String, bool> _preflightChecklist = {};

  @override
  Stream<UserProfile?> watchProfile(String userId) async* {
    yield _profile;
  }

  @override
  Future<UserProfile> ensureUserProfile(AuthUser user) async {
    return _profile ??= defaultProfileFor(user);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
  }

  @override
  Stream<List<Drone>> watchDrones(String userId) async* {
    yield _drones;
  }

  @override
  Future<void> saveDrone(String userId, Drone drone) async {
    final id = drone.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : drone.id;
    _drones.removeWhere((item) => item.id == id);
    _drones.add(
      drone.copyWith(
        id: id,
        type: DroneConstants.normalizeDroneType(drone.type),
        status: DroneConstants.normalizeDroneStatus(drone.status),
      ),
    );
  }

  @override
  Future<void> deleteDrone(String userId, String droneId) async {
    _drones.removeWhere((item) => item.id == droneId);
  }

  @override
  Stream<List<DroneBattery>> watchBatteries(String userId) async* {
    yield _batteries;
  }

  @override
  Future<void> saveBattery(String userId, DroneBattery battery) async {
    final id = battery.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : battery.id;
    _batteries.removeWhere((item) => item.id == id);
    _batteries.add(battery.copyWith(id: id));
  }

  @override
  Future<void> deleteBattery(String userId, String batteryId) async {
    _batteries.removeWhere((item) => item.id == batteryId);
  }

  @override
  Stream<List<FlightLog>> watchFlights(String userId) async* {
    yield [..._flights]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> saveFlight(String userId, FlightLog flight) async {
    final id = flight.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : flight.id;
    _flights.removeWhere((item) => item.id == id);
    _flights.add(
      FlightLog(
        id: id,
        date: flight.date,
        location: flight.location,
        coordinates: flight.coordinates,
        droneId: flight.droneId,
        batteryId: flight.batteryId,
        durationMinutes: flight.durationMinutes,
        flightType: flight.flightType,
        weather: flight.weather,
        kp: flight.kp,
        flyScore: flight.flyScore,
        notes: flight.notes,
        problems: flight.problems,
        learnings: flight.learnings,
        mediaUrls: flight.mediaUrls,
        checklist: flight.checklist,
        shotlist: flight.shotlist,
        createdAt: flight.createdAt,
        updatedAt: flight.updatedAt,
      ),
    );
  }

  @override
  Future<Map<String, bool>> loadPreflightChecklist(String userId) async {
    return _preflightChecklist;
  }

  @override
  Future<void> savePreflightChecklist(
    String userId,
    Map<String, bool> values,
  ) async {
    _preflightChecklist = values;
  }

  @override
  Future<void> addFlightHours(String userId, double hours) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        totalFlightHours: _profile!.totalFlightHours + hours,
      );
    }
  }

  @override
  Future<void> setActiveDrone(String userId, String? droneId) async {
    if (_profile != null) _profile = _profile!.copyWith(activeDroneId: droneId);
  }

  @override
  Future<void> setActiveBattery(String userId, String? batteryId) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(activeBatteryId: batteryId);
    }
  }
}
