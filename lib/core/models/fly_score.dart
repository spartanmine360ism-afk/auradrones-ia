class FlyScore {
  const FlyScore({
    required this.value,
    required this.status,
    required this.explanation,
    required this.positiveFactors,
    required this.negativeFactors,
    required this.recommendation,
  });

  final int value;
  final String status;
  final String explanation;
  final List<String> positiveFactors;
  final List<String> negativeFactors;
  final String recommendation;

  List<String> get factors => [...positiveFactors, ...negativeFactors];
}
