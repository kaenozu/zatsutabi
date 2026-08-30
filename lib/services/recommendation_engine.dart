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

  /// POIs already shown in this session, so "別の" never repeats the same
  /// suggestion and rejected places do not enter the persistent decision
  /// history.
  final Set<String> _sessionSeen = <String>{};

  double minimumRadiusKmFor(TripRange range) => switch (range) {
    TripRange.nearby => 0.0,
    TripRange.medium => 50.0,
    TripRange.far => 120.0,
  };

  double radiusKmFor(TripRange range) => switch (range) {
    TripRange.nearby => 50.0,
    TripRange.medium => 120.0,
    TripRange.far => 250.0,
  };

  Future<Poi> suggest(
    TripRange range, {
    bool indoorOnly = false,
    Position? position,
  }) async {
    final current = position ?? await locationService.currentPosition();
    final radius = radiusKmFor(range);
    // Only previously *decided* places (user pressed ここにする) are excluded
    // from future suggestions.
    final decided = (await historyStore.recentIds()).toSet();
    var candidates = await poiRepository.nearby(
      latitude: current.latitude,
      longitude: current.longitude,
      radiusKm: radius,
      minimumRadiusKm: minimumRadiusKmFor(range),
      indoorOnly: indoorOnly,
    );
    if (!indoorOnly) {
      final outdoorFriendly = await weatherProvider.isOutdoorFriendly(
        current.latitude,
        current.longitude,
      );
      if (outdoorFriendly == false) {
        final indoorCandidates = candidates
            .where((poi) => poi.isIndoor)
            .toList();
        if (indoorCandidates.isNotEmpty) candidates = indoorCandidates;
      }
    }
    candidates = candidates
        .where((poi) => !decided.contains(poi.id))
        .where((poi) => !_sessionSeen.contains(poi.id))
        .toList();
    if (candidates.isEmpty) throw const NoSuggestion();
    candidates.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    final selected = candidates.first;
    _sessionSeen.add(selected.id);
    return selected;
  }

  /// Called only when the user commits to a place (ここにする). This is the
  /// sole path that writes the persistent decision history.
  Future<void> commit(Poi poi) => historyStore.record(poi);
}

class NoSuggestion implements Exception {
  const NoSuggestion();
}
