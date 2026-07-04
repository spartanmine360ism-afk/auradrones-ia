class DroneBattery {
  const DroneBattery({
    required this.id,
    required this.name,
    required this.compatibleModel,
    required this.droneId,
    required this.cycles,
    required this.health,
    required this.lastCharge,
    required this.lastUse,
    required this.level,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String compatibleModel;
  final String? droneId;
  final int cycles;
  final int health;
  final String lastCharge;
  final String lastUse;
  final int level;
  final String status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DroneBattery copyWith({
    String? id,
    String? name,
    String? compatibleModel,
    String? droneId,
    int? cycles,
    int? health,
    String? lastCharge,
    String? lastUse,
    int? level,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DroneBattery(
      id: id ?? this.id,
      name: name ?? this.name,
      compatibleModel: compatibleModel ?? this.compatibleModel,
      droneId: droneId ?? this.droneId,
      cycles: cycles ?? this.cycles,
      health: health ?? this.health,
      lastCharge: lastCharge ?? this.lastCharge,
      lastUse: lastUse ?? this.lastUse,
      level: level ?? this.level,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'compatibleDroneId': droneId,
      'compatibleModel': compatibleModel,
      'droneId': droneId,
      'cycles': cycles,
      'health': health,
      'lastUse': lastUse,
      'lastCharge': lastCharge,
      'level': level,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DroneBattery.fromMap(String id, Map<String, dynamic> map) {
    return DroneBattery(
      id: id,
      name: map['name'] as String? ?? map['nombre'] as String? ?? '',
      compatibleModel:
          map['compatibleModel'] as String? ??
          map['compatibleDroneId'] as String? ??
          map['modeloCompatible'] as String? ??
          '',
      droneId: map['droneId'] as String?,
      cycles: ((map['cycles'] as num?) ?? (map['ciclosCarga'] as num?) ?? 0)
          .round(),
      health: ((map['health'] as num?) ?? (map['saludEstimada'] as num?) ?? 100)
          .round(),
      lastCharge:
          map['lastCharge'] as String? ?? map['ultimaCarga'] as String? ?? '',
      lastUse: map['lastUse'] as String? ?? map['ultimoUso'] as String? ?? '',
      level:
          ((map['level'] as num?) ?? (map['porcentajeActual'] as num?) ?? 100)
              .round(),
      status: map['status'] as String? ?? map['estado'] as String? ?? 'buena',
      notes: map['notes'] as String? ?? map['notas'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
