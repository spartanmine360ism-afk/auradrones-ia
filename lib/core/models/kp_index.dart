class KpSource {
  const KpSource({
    required this.source,
    required this.value,
    required this.timestamp,
    required this.available,
    this.error,
  });

  final String source;
  final double value;
  final DateTime timestamp;
  final bool available;
  final String? error;
}

class KpIndex {
  const KpIndex({
    required this.value,
    required this.risk,
    required this.recommendation,
    this.average = 0,
    this.recommended = 0,
    this.confidence = 'Baja',
    this.standardDeviation = 0,
    this.median = 0,
    this.minimum = 0,
    this.maximum = 0,
    this.updatedAt,
    this.sources = const [],
    this.dataOrigins = const [],
  });

  final double value;
  final String risk;
  final String recommendation;
  final double average;
  final double recommended;
  final String confidence;
  final double standardDeviation;
  final double median;
  final double minimum;
  final double maximum;
  final DateTime? updatedAt;
  final List<KpSource> sources;
  final List<String> dataOrigins;
}
