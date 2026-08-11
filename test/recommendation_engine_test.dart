import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:zatsutabi/data/history_store.dart';
import 'package:zatsutabi/data/poi_repository.dart';
import 'package:zatsutabi/services/location_service.dart';
import 'package:zatsutabi/services/maps_launcher.dart';
import 'package:zatsutabi/services/recommendation_engine.dart';
import 'package:zatsutabi/services/weather_provider.dart';

class FakeLocationService extends LocationService {
  @override
  Future<Position> currentPosition() async => Position(
    longitude: 139.7,
    latitude: 35.7,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

class FakeHistoryStore extends HistoryStore {
  final ids = <String>[];
  @override
  Future<List<String>> recentIds() async => ids;
  @override
  Future<void> record(poi) async => ids.insert(0, poi.id);
}

class FakeMapsLauncher extends MapsLauncher {}

void main() {
  test('returns one nearby suggestion and records it', () async {
    final history = FakeHistoryStore();
    final engine = RecommendationEngine(
      poiRepository: PoiRepository(),
      historyStore: history,
      locationService: FakeLocationService(),
      weatherProvider: const NoWeatherProvider(),
      mapsLauncher: FakeMapsLauncher(),
    );

    final result = await engine.suggest(TripRange.nearby);

    expect(result.name, isNotEmpty);
    expect(history.ids, contains(result.id));
  });

  test('can filter indoor suggestions', () async {
    final engine = RecommendationEngine(
      poiRepository: PoiRepository(),
      historyStore: FakeHistoryStore(),
      locationService: FakeLocationService(),
      weatherProvider: const NoWeatherProvider(),
      mapsLauncher: FakeMapsLauncher(),
    );

    final result = await engine.suggest(TripRange.nearby, indoorOnly: true);

    expect(result.indoor, isTrue);
  });
}
