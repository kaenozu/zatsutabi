import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zatsutabi/data/history_store.dart';
import 'package:zatsutabi/data/poi_repository.dart';
import 'package:zatsutabi/models/poi.dart';
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

class RainyWeatherProvider implements WeatherProvider {
  @override
  Future<bool?> isOutdoorFriendly(double latitude, double longitude) async =>
      false;
}

void main() {
  test('builds a Google Maps URL without an API key', () {
    final uri = MapsLauncher().destinationUri(PoiRepositoryTestPoi.value);

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '35.7,139.7');
  });

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

  test('loads bundled nationwide POIs outside Tokyo', () async {
    final repository = PoiRepository();

    final osaka = await repository.nearby(
      latitude: 34.6545,
      longitude: 135.4289,
      radiusKm: 50,
    );
    final sapporo = await repository.nearby(
      latitude: 43.0608,
      longitude: 141.3478,
      radiusKm: 50,
    );

    expect(osaka, isNotEmpty);
    expect(sapporo, isNotEmpty);
  });

  test('persists readable history entries', () async {
    SharedPreferences.setMockInitialValues({});
    final store = HistoryStore();
    const poi = Poi(
      id: 'history-test',
      name: '履歴テスト',
      category: '博物館',
      latitude: 35.7,
      longitude: 139.7,
      indoor: true,
    );

    await store.record(poi);
    final entries = await store.entries();

    expect(entries, hasLength(1));
    expect(entries.single['name'], '履歴テスト');
    expect(entries.single['category'], '博物館');
  });

  test('ignores malformed history records', () async {
    SharedPreferences.setMockInitialValues({
      'suggestion_history_v2': ['not-json', '{"name":"missing id"}'],
    });
    final store = HistoryStore();

    expect(await store.recentIds(), isEmpty);
    expect(await store.entries(), isEmpty);
  });

  test('serializes concurrent history writes', () async {
    SharedPreferences.setMockInitialValues({});
    final store = HistoryStore();
    const first = Poi(
      id: 'first',
      name: 'First',
      category: 'test',
      latitude: 35.0,
      longitude: 139.0,
      indoor: false,
    );
    const second = Poi(
      id: 'second',
      name: 'Second',
      category: 'test',
      latitude: 35.1,
      longitude: 139.1,
      indoor: false,
    );

    await Future.wait([store.record(first), store.record(second)]);

    expect(await store.recentIds(), containsAll(<String>['first', 'second']));
  });

  test('prefers indoor suggestions when weather is unsuitable', () async {
    final engine = RecommendationEngine(
      poiRepository: PoiRepository(),
      historyStore: FakeHistoryStore(),
      locationService: FakeLocationService(),
      weatherProvider: RainyWeatherProvider(),
      mapsLauncher: FakeMapsLauncher(),
    );

    final result = await engine.suggest(TripRange.nearby);

    expect(result.indoor, isTrue);
  });
}

class PoiRepositoryTestPoi {
  static const value = Poi(
    id: 'test',
    name: 'Test',
    category: 'Test',
    latitude: 35.7,
    longitude: 139.7,
    indoor: false,
  );
}
