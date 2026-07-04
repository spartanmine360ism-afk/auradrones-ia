class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.pilotLevel,
    required this.mainGoal,
    required this.createdAt,
    required this.updatedAt,
    required this.totalFlightHours,
    required this.emailVerified,
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
  final DateTime updatedAt;
  final double totalFlightHours;
  final bool emailVerified;
  final String? activeDroneId;
  final String? activeBatteryId;
  final Map<String, bool> notifications;
  final bool onboardingComplete;

  UserProfile copyWith({
    String? name,
    String? email,
    String? pilotLevel,
    String? mainGoal,
    double? totalFlightHours,
    bool? emailVerified,
    String? activeDroneId,
    String? activeBatteryId,
    Map<String, bool>? notifications,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      pilotLevel: pilotLevel ?? this.pilotLevel,
      mainGoal: mainGoal ?? this.mainGoal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      totalFlightHours: totalFlightHours ?? this.totalFlightHours,
      emailVerified: emailVerified ?? this.emailVerified,
      activeDroneId: activeDroneId ?? this.activeDroneId,
      activeBatteryId: activeBatteryId ?? this.activeBatteryId,
      notifications: notifications ?? this.notifications,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'pilotLevel': pilotLevel,
      'mainGoal': mainGoal,
      'totalFlightHours': totalFlightHours,
      'onboardingComplete': onboardingComplete,
      'emailVerified': emailVerified,
      'activeDroneId': activeDroneId,
      'activeBatteryId': activeBatteryId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notifications': notifications,
    };
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    final notificationsMap =
        (map['notifications'] ?? map['configuracionNotificaciones'])
            as Map<String, dynamic>?;

    return UserProfile(
      id: id,
      name: map['name'] as String? ?? map['nombre'] as String? ?? '',
      email: map['email'] as String? ?? '',
      pilotLevel:
          map['pilotLevel'] as String? ??
          map['nivelPiloto'] as String? ??
          'Principiante',
      mainGoal:
          map['mainGoal'] as String? ??
          map['objetivoPrincipal'] as String? ??
          'Hobby',
      createdAt:
          DateTime.tryParse(
            map['createdAt'] as String? ??
                map['fechaCreacion'] as String? ??
                '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      totalFlightHours:
          ((map['totalFlightHours'] as num?) ??
                  (map['horasTotalesVuelo'] as num?) ??
                  0)
              .toDouble(),
      emailVerified: map['emailVerified'] == true,
      activeDroneId:
          map['activeDroneId'] as String? ?? map['dronActivo'] as String?,
      activeBatteryId:
          map['activeBatteryId'] as String? ?? map['bateriaActiva'] as String?,
      notifications:
          notificationsMap?.map((key, value) => MapEntry(key, value == true)) ??
          const {
            'weather': true,
            'kp': true,
            'maintenance': true,
            'goldenHour': true,
          },
      onboardingComplete:
          map['onboardingComplete'] == true ||
          map['onboardingCompleto'] == true,
    );
  }
}
