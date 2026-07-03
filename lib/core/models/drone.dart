class Drone {
  const Drone({
    required this.id,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.weightGrams,
    required this.type,
    required this.flightHours,
    required this.flightsCount,
    required this.status,
    required this.nextMaintenance,
    required this.purchaseDate,
    required this.notes,
    required this.photoUrl,
    required this.createdAt,
  });

  final String id;
  final String brand;
  final String model;
  final String serialNumber;
  final int weightGrams;
  final String type;
  final double flightHours;
  final int flightsCount;
  final String status;
  final String nextMaintenance;
  final DateTime? purchaseDate;
  final String notes;
  final String? photoUrl;
  final DateTime createdAt;

  Drone copyWith({
    String? id,
    String? brand,
    String? model,
    String? serialNumber,
    int? weightGrams,
    String? type,
    double? flightHours,
    int? flightsCount,
    String? status,
    String? nextMaintenance,
    DateTime? purchaseDate,
    String? notes,
    String? photoUrl,
  }) {
    return Drone(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      weightGrams: weightGrams ?? this.weightGrams,
      type: type ?? this.type,
      flightHours: flightHours ?? this.flightHours,
      flightsCount: flightsCount ?? this.flightsCount,
      status: status ?? this.status,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'marca': brand,
      'modelo': model,
      'numeroSerie': serialNumber,
      'peso': weightGrams,
      'tipo': type,
      'fechaCompra': purchaseDate?.toIso8601String(),
      'horasVuelo': flightHours,
      'vuelosRealizados': flightsCount,
      'estado': status,
      'mantenimientoProximo': nextMaintenance,
      'notas': notes,
      'foto': photoUrl,
      'fechaCreacion': createdAt.toIso8601String(),
    };
  }

  factory Drone.fromMap(String id, Map<String, dynamic> map) {
    return Drone(
      id: id,
      brand: map['marca'] as String? ?? '',
      model: map['modelo'] as String? ?? '',
      serialNumber: map['numeroSerie'] as String? ?? '',
      weightGrams: ((map['peso'] as num?) ?? 0).round(),
      type: map['tipo'] as String? ?? 'Otro',
      purchaseDate: DateTime.tryParse(map['fechaCompra'] as String? ?? ''),
      flightHours: ((map['horasVuelo'] as num?) ?? 0).toDouble(),
      flightsCount: ((map['vuelosRealizados'] as num?) ?? 0).round(),
      status: map['estado'] as String? ?? 'Listo',
      nextMaintenance: map['mantenimientoProximo'] as String? ?? '',
      notes: map['notas'] as String? ?? '',
      photoUrl: map['foto'] as String?,
      createdAt:
          DateTime.tryParse(map['fechaCreacion'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
