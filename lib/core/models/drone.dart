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
    required this.updatedAt,
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
  final DateTime updatedAt;

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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'weightGrams': weightGrams,
      'type': type,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'totalFlightHours': flightHours,
      'flightsCount': flightsCount,
      'status': status,
      'nextMaintenance': nextMaintenance,
      'notes': notes,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Drone.fromMap(String id, Map<String, dynamic> map) {
    return Drone(
      id: id,
      brand: map['brand'] as String? ?? map['marca'] as String? ?? '',
      model: map['model'] as String? ?? map['modelo'] as String? ?? '',
      serialNumber:
          map['serialNumber'] as String? ?? map['numeroSerie'] as String? ?? '',
      weightGrams: ((map['weightGrams'] as num?) ?? (map['peso'] as num?) ?? 0)
          .round(),
      type: map['type'] as String? ?? map['tipo'] as String? ?? 'Otro',
      purchaseDate: DateTime.tryParse(
        map['purchaseDate'] as String? ?? map['fechaCompra'] as String? ?? '',
      ),
      flightHours:
          ((map['totalFlightHours'] as num?) ??
                  (map['flightHours'] as num?) ??
                  (map['horasVuelo'] as num?) ??
                  0)
              .toDouble(),
      flightsCount:
          ((map['flightsCount'] as num?) ??
                  (map['vuelosRealizados'] as num?) ??
                  0)
              .round(),
      status: map['status'] as String? ?? map['estado'] as String? ?? 'Listo',
      nextMaintenance:
          map['nextMaintenance'] as String? ??
          map['mantenimientoProximo'] as String? ??
          '',
      notes: map['notes'] as String? ?? map['notas'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['foto'] as String?,
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
    );
  }
}
