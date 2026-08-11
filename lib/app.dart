import 'package:flutter/material.dart';

import 'data/history_store.dart';
import 'data/poi_repository.dart';
import 'services/location_service.dart';
import 'services/maps_launcher.dart';
import 'services/recommendation_engine.dart';
import 'services/weather_provider.dart';
import 'ui/app_shell.dart';

class ZatsutabiApp extends StatefulWidget {
  const ZatsutabiApp({super.key});

  @override
  State<ZatsutabiApp> createState() => _ZatsutabiAppState();
}

class _ZatsutabiAppState extends State<ZatsutabiApp> {
  late final HistoryStore historyStore;
  late final PoiRepository poiRepository;
  late final RecommendationEngine engine;

  @override
  void initState() {
    super.initState();
    historyStore = HistoryStore();
    poiRepository = PoiRepository();
    engine = RecommendationEngine(
      poiRepository: poiRepository,
      historyStore: historyStore,
      locationService: LocationService(),
      weatherProvider: const NoWeatherProvider(),
      mapsLauncher: MapsLauncher(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '雑旅',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D3F),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFDF9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3EC),
        fontFamily: 'sans',
      ),
      home: AppShell(engine: engine, historyStore: historyStore),
    );
  }
}
