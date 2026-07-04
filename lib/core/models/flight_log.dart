class FlightLog {
  const FlightLog({
    required this.id,
    required this.date,
    required this.location,
    required this.coordinates,
    required this.droneId,
    required this.batteryId,
    required this.durationMinutes,
    required this.flightType,
    required this.weather,
    required this.kp,
    required this.flyScore,
    required this.notes,
    required this.problems,
    required this.learnings,
    required this.mediaUrls,
    required this.checklist,
    required this.shotlist,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String location;
  final String coordinates;
  final String droneId;
  final String batteryId;
  final int durationMinutes;
  final String flightType;
  final String weather;
  final double kp;
  final int flyScore;
  final String notes;
  final String problems;
  final String learnings;
  final List<String> mediaUrls;
  final Map<String, bool> checklist;
  final List<String> shotlist;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'locationName': location,
      'coordinates': coordinates,
      'droneId': droneId,
      'batteryId': batteryId,
      'durationMinutes': durationMinutes,
      'flightType': flightType,
      'weather': weather,
      'kp': kp,
      'flyScore': flyScore,
      'notes': notes,
      'problems': problems,
      'learnings': learnings,
      'mediaUrls': mediaUrls,
      'checklist': checklist,
      'shotlist': shotlist,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlightLog.fromMap(String id, Map<String, dynamic> map) {
    return FlightLog(
      id: id,
      date:
          DateTime.tryParse(
            map['date'] as String? ?? map['fecha'] as String? ?? '',
          ) ??
          DateTime.now(),
      location:
          map['locationName'] as String? ?? map['ubicacion'] as String? ?? '',
      coordinates:
          map['coordinates'] as String? ?? map['coordenadas'] as String? ?? '',
      droneId: map['droneId'] as String? ?? map['dronUsado'] as String? ?? '',
      batteryId:
          map['batteryId'] as String? ?? map['bateriaUsada'] as String? ?? '',
      durationMinutes:
          ((map['durationMinutes'] as num?) ?? (map['duracion'] as num?) ?? 0)
              .round(),
      flightType:
          map['flightType'] as String? ?? map['tipoVuelo'] as String? ?? '',
      weather: map['weather'] as String? ?? map['clima'] as String? ?? '',
      kp: ((map['kp'] as num?) ?? 0).toDouble(),
      flyScore: ((map['flyScore'] as num?) ?? 0).round(),
      notes: map['notes'] as String? ?? map['notas'] as String? ?? '',
      problems: map['problems'] as String? ?? map['problemas'] as String? ?? '',
      learnings:
          map['learnings'] as String? ?? map['aprendizajes'] as String? ?? '',
      mediaUrls:
          ((map['mediaUrls'] ?? map['fotosVideos']) as List<dynamic>? ?? [])
              .map((item) => '$item')
              .toList(),
      checklist: ((map['checklist'] as Map<String, dynamic>?) ?? {}).map(
        (key, value) => MapEntry(key, value == true),
      ),
      shotlist: (map['shotlist'] as List<dynamic>? ?? [])
          .map((item) => '$item')
          .toList(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
