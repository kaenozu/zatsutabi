import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../data/history_store.dart';
import '../data/poi_repository.dart';
import '../models/poi.dart';
import 'location_service.dart';
import 'maps_launcher.dart';
import 'weather_provider.dart';

enum TripRange { nearby, medium, far }

class RecommendationEngine {
  RecommendationEngine({
    required this.poiRepository,
    required this.historyStore,
    required this.locationService,
    required this.weatherProvider,
    required this.mapsLauncher,
  });
  final PoiRepository poiRepository;
  final HistoryStore historyStore;
  final LocationService locationService;
  final WeatherProvider weatherProvider;
  final MapsLauncher mapsLauncher;

  Future<Poi> suggest(
    TripRange range, {
    bool indoorOnly = false,
    Position? position,
  }) async {
    final current = position ?? await locationService.currentPosition();
    final radius = switch (range) {
      TripRange.nearby => 50.0,
      TripRange.medium => 120.0,
      TripRange.far => 250.0,
    };
    final excluded = (await historyStore.recentIds()).toSet();
    var candidates = await poiRepository.nearby(
      latitude: current.latitude,
      longitude: current.longitude,
      radiusKm: radius,
      indoorOnly: indoorOnly,
    );
    final unseen = candidates
        .where((poi) => !excluded.contains(poi.id))
        .toList();
    if (unseen.isNotEmpty) candidates = unseen;
    if (candidates.isEmpty) throw const NoSuggestion();
    candidates.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    final selected = candidates.first;
    await historyStore.record(selected);
    return selected;
  }
}

class NoSuggestion implements Exception {
  const NoSuggestion();
}
