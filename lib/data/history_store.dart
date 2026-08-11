import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/poi.dart';

class HistoryStore {
  static const _key = 'suggestion_history';

  Future<List<String>> recentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> record(Poi poi) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];
    final next = <String>[
      poi.id,
      ...current.where((id) => id != poi.id),
    ].take(30).toList();
    await prefs.setStringList(_key, next);
  }

  Future<List<Map<String, dynamic>>> entries() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? <String>[];
    return ids
        .map((id) => jsonDecode('{"id":"$id"}') as Map<String, dynamic>)
        .toList();
  }
}
