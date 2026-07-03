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

  Map<String, dynamic> toMap() {
    return {
      'fecha': date.toIso8601String(),
      'ubicacion': location,
      'coordenadas': coordinates,
      'dronUsado': droneId,
      'bateriaUsada': batteryId,
      'duracion': durationMinutes,
      'tipoVuelo': flightType,
      'clima': weather,
      'kp': kp,
      'flyScore': flyScore,
      'notas': notes,
      'problemas': problems,
      'aprendizajes': learnings,
      'fotosVideos': mediaUrls,
    };
  }
}
