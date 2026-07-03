class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.accuracyMeters,
    required this.isMocked,
  });

  final double latitude;
  final double longitude;
  final String city;
  final double accuracyMeters;
  final bool isMocked;

  String get coordinates =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
