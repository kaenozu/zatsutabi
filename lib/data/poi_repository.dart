import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/poi.dart';

class PoiRepository {
  static const _fallback = <Poi>[
    Poi(
      id: 'tokyo-park',
      name: '井の頭恩賜公園',
      category: '自然・散歩',
      latitude: 35.7008,
      longitude: 139.5703,
      indoor: false,
    ),
    Poi(
      id: 'tokyo-museum',
      name: '国立科学博物館',
      category: '博物館',
      latitude: 35.7207,
      longitude: 139.7765,
      indoor: true,
    ),
    Poi(
      id: 'saitama-nagatoro',
      name: '長瀞岩畳',
      category: '景勝地',
      latitude: 36.0946,
      longitude: 139.1104,
      indoor: false,
    ),
    Poi(
      id: 'osaka-aquarium',
      name: '海遊館',
      category: '水族館',
      latitude: 34.6545,
      longitude: 135.4289,
      indoor: true,
    ),
    Poi(
      id: 'kyoto-arashiyama',
      name: '嵐山竹林',
      category: '自然・散歩',
      latitude: 35.017,
      longitude: 135.6713,
      indoor: false,
    ),
    Poi(
      id: 'fukuoka-museum',
      name: '福岡市博物館',
      category: '博物館',
      latitude: 33.5938,
      longitude: 130.3515,
      indoor: true,
    ),
    Poi(
      id: 'sapporo-park',
      name: '大通公園',
      category: '自然・散歩',
      latitude: 43.0608,
      longitude: 141.3478,
      indoor: false,
    ),
  ];

  Database? _database;
  Future<Database?>? _openingDatabase;

  Future<Database?> _openDatabase() async {
    if (_database != null) return _database;
    if (_openingDatabase != null) return _openingDatabase;
    _openingDatabase = _openDatabaseOnce();
    final database = await _openingDatabase;
    _openingDatabase = null;
    return database;
  }

  Future<Database?> _openDatabaseOnce() async {
    try {
      final databasesPath = await getDatabasesPath();
      final databasePath = path.join(databasesPath, 'poi_osm.sqlite');
      if (!await File(databasePath).exists()) {
        final bytes = (await rootBundle.load(
          'assets/poi_osm.sqlite',
        )).buffer.asUint8List();
        await File(databasePath).writeAsBytes(bytes, flush: true);
      }
      _database = await openDatabase(databasePath, readOnly: true);
      return _database;
    } catch (_) {
      return null;
    }
  }

  Future<List<Poi>> nearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
    bool indoorOnly = false,
  }) async {
    final database = await _openDatabase();
    final latitudeDelta = radiusKm / 111.0;
    final longitudeDelta = radiusKm / (111.0 * cos(_radians(latitude)));
    final rows = database == null
        ? const <Map<String, Object?>>[]
        : await database.query(
            'poi',
            where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
            whereArgs: [
              latitude - latitudeDelta,
              latitude + latitudeDelta,
              longitude - longitudeDelta,
              longitude + longitudeDelta,
            ],
            limit: 5000,
          );
    final source = rows.isEmpty
        ? _fallback
        : rows
              .map(
                (row) => Poi(
                  id: row['id']! as String,
                  name: row['name']! as String,
                  category: row['category']! as String,
                  latitude: row['latitude']! as double,
                  longitude: row['longitude']! as double,
                  indoor: row['indoor'] == 1,
                ),
              )
              .toList();
    return source
        .where((poi) => !indoorOnly || poi.indoor)
        .where(
          (poi) =>
              _distanceKm(latitude, longitude, poi.latitude, poi.longitude) <=
              radiusKm,
        )
        .toList();
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earth = 6371.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_radians(lat1)) *
            cos(_radians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earth * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _radians(double value) => value * pi / 180;
}
