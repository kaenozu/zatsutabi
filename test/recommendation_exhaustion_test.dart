import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:zatsutabi/data/history_store.dart';
import 'package:zatsutabi/data/poi_repository.dart';
import 'package:zatsutabi/models/poi.dart';
import 'package:zatsutabi/services/location_service.dart';
import 'package:zatsutabi/services/maps_launcher.dart';
import 'package:zatsutabi/services/recommendation_engine.dart';
import 'package:zatsutabi/services/weather_provider.dart';

final _position = Position(
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

const _poiA = Poi(
  id: 'a',
  name: 'A',
  category: 'test',
  latitude: 35.7,
  longitude: 139.7,
  indoor: IndoorStatus.indoor,
);

const _poiB = Poi(
  id: 'b',
  name: 'B',
  category: 'test',
  latitude: 35.7,
  longitude: 139.7,
  indoor: IndoorStatus.indoor,
);

class _FakePoiRepository extends PoiRepository {
  _FakePoiRepository(this.items);

  final List<Poi> items;

  @override
  Future<List<Poi>> nearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
    double minimumRadiusKm = 0,
    bool indoorOnly = false,
  }) async => items.where((poi) => !indoorOnly || poi.isIndoor).toList();
}

class _FakeHistoryStore extends HistoryStore {
  _FakeHistoryStore([Iterable<String> ids = const []]) : ids = ids.toList();

  final List<String> ids;

  @override
  Future<List<String>> recentIds() async => List<String>.of(ids);

  @override
  Future<void> record(Poi poi) async => ids.insert(0, poi.id);
}

class _UnusedLocationService extends LocationService {}
class _FakeMapsLauncher extends MapsLauncher {}

RecommendationEngine _engine(List<Poi> items, {Iterable<String> decided = const []}) {
  return RecommendationEngine(
    poiRepository: _FakePoiRepository(items),
    historyStore: _FakeHistoryStore(decided),
    locationService: _UnusedLocationService(),
    weatherProvider: const NoWeatherProvider(),
    mapsLauncher: _FakeMapsLauncher(),
  );
}

void main() {
  test('one candidate is not reselected after it has been seen', () async {
    final engine = _engine([_poiA]);

    expect((await engine.suggest(TripRange.nearby, position: _position)).id, 'a');
    await expectLater(
      engine.suggest(TripRange.nearby, position: _position),
      throwsA(isA<NoSuggestion>()),
    );
  });

  test('all decided candidates produce NoSuggestion', () async {
    final engine = _engine([_poiA, _poiB], decided: ['a', 'b']);

    await expectLater(
      engine.suggest(TripRange.nearby, position: _position),
      throwsA(isA<NoSuggestion>()),
    );
  });

  test('mixed decided and unseen candidates selects only unseen', () async {
    final engine = _engine([_poiA, _poiB], decided: ['a']);

    final selected = await engine.suggest(TripRange.nearby, position: _position);

    expect(selected.id, 'b');
  });
}
