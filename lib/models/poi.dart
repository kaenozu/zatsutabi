/// Indoor classification: 0 = outdoor, 1 = indoor, 2 = unknown.
enum IndoorStatus { outdoor, indoor, unknown }

class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.indoor,
    this.description,
  });

  factory Poi.fromRow(Map<String, Object?> row) {
    final indoorValue = row['indoor'];
    // DB stores 0/1/2; older bundles may only have 0/1.
    final status = switch (indoorValue) {
      1 => IndoorStatus.indoor,
      0 => IndoorStatus.outdoor,
      _ => IndoorStatus.unknown,
    };
    return Poi(
      id: row['id']! as String,
      name: row['name']! as String,
      category: row['category']! as String,
      latitude: row['latitude']! as double,
      longitude: row['longitude']! as double,
      indoor: status,
    );
  }

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final IndoorStatus indoor;
  final String? description;

  /// True only when the POI is *known* to be indoors.
  bool get isIndoor => indoor == IndoorStatus.indoor;
}
