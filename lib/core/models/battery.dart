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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'modeloCompatible': compatibleModel,
      'droneId': droneId,
      'ciclosCarga': cycles,
      'saludEstimada': health,
      'ultimoUso': lastUse,
      'ultimaCarga': lastCharge,
      'porcentajeActual': level,
      'estado': status,
      'notas': notes,
    };
  }

  factory DroneBattery.fromMap(String id, Map<String, dynamic> map) {
    return DroneBattery(
      id: id,
      name: map['nombre'] as String? ?? '',
      compatibleModel: map['modeloCompatible'] as String? ?? '',
      droneId: map['droneId'] as String?,
      cycles: ((map['ciclosCarga'] as num?) ?? 0).round(),
      health: ((map['saludEstimada'] as num?) ?? 100).round(),
      lastCharge: map['ultimaCarga'] as String? ?? '',
      lastUse: map['ultimoUso'] as String? ?? '',
      level: ((map['porcentajeActual'] as num?) ?? 100).round(),
      status: map['estado'] as String? ?? 'buena',
      notes: map['notas'] as String? ?? '',
    );
  }
}
