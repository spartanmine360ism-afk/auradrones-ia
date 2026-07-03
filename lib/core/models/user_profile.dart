class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.pilotLevel,
    required this.mainGoal,
    required this.createdAt,
    required this.totalFlightHours,
    required this.activeDroneId,
    required this.activeBatteryId,
    required this.notifications,
    required this.onboardingComplete,
  });

  final String id;
  final String name;
  final String email;
  final String pilotLevel;
  final String mainGoal;
  final DateTime createdAt;
  final double totalFlightHours;
  final String? activeDroneId;
  final String? activeBatteryId;
  final Map<String, bool> notifications;
  final bool onboardingComplete;

  UserProfile copyWith({
    String? name,
    String? pilotLevel,
    String? mainGoal,
    double? totalFlightHours,
    String? activeDroneId,
    String? activeBatteryId,
    Map<String, bool>? notifications,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      pilotLevel: pilotLevel ?? this.pilotLevel,
      mainGoal: mainGoal ?? this.mainGoal,
      createdAt: createdAt,
      totalFlightHours: totalFlightHours ?? this.totalFlightHours,
      activeDroneId: activeDroneId ?? this.activeDroneId,
      activeBatteryId: activeBatteryId ?? this.activeBatteryId,
      notifications: notifications ?? this.notifications,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'email': email,
      'nivelPiloto': pilotLevel,
      'objetivoPrincipal': mainGoal,
      'fechaCreacion': createdAt.toIso8601String(),
      'horasTotalesVuelo': totalFlightHours,
      'dronActivo': activeDroneId,
      'bateriaActiva': activeBatteryId,
      'configuracionNotificaciones': notifications,
      'onboardingCompleto': onboardingComplete,
    };
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['nombre'] as String? ?? '',
      email: map['email'] as String? ?? '',
      pilotLevel: map['nivelPiloto'] as String? ?? 'Principiante',
      mainGoal: map['objetivoPrincipal'] as String? ?? 'Hobby',
      createdAt:
          DateTime.tryParse(map['fechaCreacion'] as String? ?? '') ??
          DateTime.now(),
      totalFlightHours: ((map['horasTotalesVuelo'] as num?) ?? 0).toDouble(),
      activeDroneId: map['dronActivo'] as String?,
      activeBatteryId: map['bateriaActiva'] as String?,
      notifications:
          (map['configuracionNotificaciones'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value == true),
          ) ??
          const {
            'weather': true,
            'kp': true,
            'maintenance': true,
            'goldenHour': true,
          },
      onboardingComplete: map['onboardingCompleto'] == true,
    );
  }
}
