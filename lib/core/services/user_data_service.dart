import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<void> saveFlight(String userId, FlightLog flight);
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
    totalFlightHours: 0,
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

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.watchProfile(userId);
    }
    return _users.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : UserProfile.fromMap(doc.id, data);
    });
  }

  @override
  Future<UserProfile> ensureUserProfile(AuthUser user) async {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.ensureUserProfile(user);
    }
    final ref = _users.doc(user.id);
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.id, doc.data()!);
    }
    final profile = defaultProfileFor(user);
    await ref.set(profile.toMap());
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.saveProfile(profile);
    }
    await _users.doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<List<Drone>> watchDrones(String userId) {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.watchDrones(userId);
    }
    return _users
        .doc(userId)
        .collection('drones')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Drone.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveDrone(String userId, Drone drone) async {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.saveDrone(userId, drone);
    }
    final ref = drone.id.isEmpty
        ? _users.doc(userId).collection('drones').doc()
        : _users.doc(userId).collection('drones').doc(drone.id);
    await ref.set(drone.copyWith(id: ref.id).toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteDrone(String userId, String droneId) async {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.deleteDrone(userId, droneId);
    }
    await _users.doc(userId).collection('drones').doc(droneId).delete();
  }

  @override
  Stream<List<DroneBattery>> watchBatteries(String userId) {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.watchBatteries(userId);
    }
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
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.saveBattery(userId, battery);
    }
    final ref = battery.id.isEmpty
        ? _users.doc(userId).collection('batteries').doc()
        : _users.doc(userId).collection('batteries').doc(battery.id);
    await ref.set(
      battery.copyWith(id: ref.id).toMap(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteBattery(String userId, String batteryId) async {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.deleteBattery(userId, batteryId);
    }
    await _users.doc(userId).collection('batteries').doc(batteryId).delete();
  }

  @override
  Future<void> saveFlight(String userId, FlightLog flight) async {
    if (!FirebaseBootstrap.initialized) {
      return DevUserDataService.instance.saveFlight(userId, flight);
    }
    final ref = flight.id.isEmpty
        ? _users.doc(userId).collection('flights').doc()
        : _users.doc(userId).collection('flights').doc(flight.id);
    await ref.set(flight.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> addFlightHours(String userId, double hours) async {
    final profile = await ensureUserProfile(
      AuthUser(id: userId, email: '', name: ''),
    );
    await saveProfile(
      profile.copyWith(totalFlightHours: profile.totalFlightHours + hours),
    );
  }

  @override
  Future<void> setActiveDrone(String userId, String? droneId) async {
    final profile = await ensureUserProfile(
      AuthUser(id: userId, email: '', name: ''),
    );
    await saveProfile(profile.copyWith(activeDroneId: droneId));
  }

  @override
  Future<void> setActiveBattery(String userId, String? batteryId) async {
    final profile = await ensureUserProfile(
      AuthUser(id: userId, email: '', name: ''),
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
    _drones.add(drone.copyWith(id: id));
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
  Future<void> saveFlight(String userId, FlightLog flight) async {}

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
