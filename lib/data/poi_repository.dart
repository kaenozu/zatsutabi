import 'dart:math';

import '../models/poi.dart';

class PoiRepository {
  // The generated SQLite asset is the production-shaped source. These seed rows
  // keep the first build runnable before the large Japan extract is installed.
  static const _pois = <Poi>[
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

  Future<List<Poi>> nearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
    bool indoorOnly = false,
  }) async {
    return _pois.where((poi) => !indoorOnly || poi.indoor).where((poi) {
      return _distanceKm(latitude, longitude, poi.latitude, poi.longitude) <=
          radiusKm;
    }).toList();
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
