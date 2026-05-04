class WeatherModel {
  final double temperature;
  final String description;
  final String city;

  WeatherModel({
    required this.temperature,
    required this.description,
    required this.city,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num).toDouble(),
      description: json['description'] as String,
      city: json['city'] as String,
    );
  }
}
