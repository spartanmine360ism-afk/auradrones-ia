class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.coordinates,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.windKmh,
    required this.gustKmh,
    required this.windDirection,
    required this.humidity,
    required this.visibilityKm,
    required this.cloudCover,
    required this.rainChance,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
  });

  final String city;
  final String coordinates;
  final double temperatureC;
  final double feelsLikeC;
  final double windKmh;
  final double gustKmh;
  final String windDirection;
  final int humidity;
  final double visibilityKm;
  final int cloudCover;
  final int rainChance;
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hourly;
}

class HourlyForecast {
  const HourlyForecast(this.time, this.tempC, this.windKmh, this.rainChance);

  final String time;
  final double tempC;
  final double windKmh;
  final int rainChance;
}
