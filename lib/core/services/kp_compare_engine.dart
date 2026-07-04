import 'dart:math';

import '../models/kp_index.dart';

/// Compares independent KP providers and rejects values that do not agree with
/// the group. It keeps all raw source states for transparency in the UI.
class KpCompareEngine {
  KpIndex compare(List<KpSource> sources) {
    final available = sources.where((source) => source.available).toList();

    if (available.isEmpty) {
      return KpIndex(
        value: 0,
        risk: 'KP no disponible temporalmente',
        recommendation:
            'No se pudo actualizar KP. Vuela conservador y reintenta antes de despegar.',
        sources: sources,
      );
    }

    final filtered = _withoutOutliers(available);
    final trusted = filtered.isEmpty ? available : filtered;
    final values = trusted.map((source) => source.value).toList()..sort();
    final average = values.reduce((a, b) => a + b) / values.length;
    final median = _median(values);
    final recommended = (average + median) / 2;
    final standardDeviation = _standardDeviation(values, average);
    final confidence = switch (trusted.length) {
      >= 3 => 'Alta',
      2 => 'Media',
      _ => 'Baja',
    };

    return KpIndex(
      value: median,
      average: average,
      recommended: recommended,
      confidence: confidence,
      standardDeviation: standardDeviation,
      median: median,
      minimum: values.first,
      maximum: values.last,
      updatedAt: trusted
          .map((source) => source.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b),
      sources: sources,
      dataOrigins: trusted.map((source) => source.source).toList(),
      risk: _risk(recommended),
      recommendation: _recommendation(recommended, confidence),
    );
  }

  List<KpSource> _withoutOutliers(List<KpSource> sources) {
    if (sources.length < 3) return sources;

    return sources.where((source) {
      final others = sources.where((item) => item.source != source.source);
      final otherAverage =
          others.map((item) => item.value).reduce((a, b) => a + b) /
          others.length;
      return (source.value - otherAverage).abs() <= 2;
    }).toList();
  }

  double _median(List<double> sortedValues) {
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) return sortedValues[middle];
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }

  double _standardDeviation(List<double> values, double average) {
    if (values.length < 2) return 0;

    final variance =
        values.map((value) => pow(value - average, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  String _risk(double value) {
    if (value >= 6) return 'No recomendable';
    if (value >= 5) return 'Riesgo GPS';
    if (value >= 4) return 'Precaucion';
    return 'Estable';
  }

  String _recommendation(double value, String confidence) {
    final suffix = 'Confianza $confidence.';
    if (value >= 6) {
      return 'Evita vuelos largos, autonomos o dependientes de GPS. $suffix';
    }
    if (value >= 5) {
      return 'Riesgo GPS elevado; vuela cerca y mantente en modo manual si hace falta. $suffix';
    }
    if (value >= 4) {
      return 'Vuela con margen, revisa satelites antes de despegar y evita misiones largas. $suffix';
    }
    return 'Actividad geomagnetica favorable para vuelo normal. $suffix';
  }
}
