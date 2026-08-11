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

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final bool indoor;
  final String? description;
}
