import 'package:flutter_test/flutter_test.dart';
import 'package:zatsutabi/app.dart';
import 'package:zatsutabi/data/history_store.dart';
import 'package:zatsutabi/data/poi_repository.dart';
import 'package:zatsutabi/services/location_service.dart';
import 'package:zatsutabi/services/maps_launcher.dart';
import 'package:zatsutabi/services/recommendation_engine.dart';
import 'package:zatsutabi/services/weather_provider.dart';

void main() {
  testWidgets('renders the decision-first home screen', (tester) async {
    await tester.pumpWidget(const ZatsutabiApp());
    expect(find.text('今日どっか行く？'), findsOneWidget);
    expect(find.text('近場'), findsOneWidget);
    expect(find.text('ちょい遠出'), findsOneWidget);
    expect(find.text('遠出'), findsOneWidget);
  });

  test('distance ranges are explicit and non-overlapping', () {
    final engine = RecommendationEngine(
      poiRepository: PoiRepository(),
      historyStore: HistoryStore(),
      locationService: LocationService(),
      weatherProvider: const NoWeatherProvider(),
      mapsLauncher: MapsLauncher(),
    );
    expect(engine.minimumRadiusKmFor(TripRange.nearby), 0);
    expect(engine.radiusKmFor(TripRange.nearby), 50);
    expect(engine.minimumRadiusKmFor(TripRange.medium), 50);
    expect(engine.radiusKmFor(TripRange.medium), 120);
    expect(engine.minimumRadiusKmFor(TripRange.far), 120);
    expect(engine.radiusKmFor(TripRange.far), 250);
  });
}
