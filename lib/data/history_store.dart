import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/poi.dart';

class HistoryStore {
  static const _key = 'suggestion_history_v2';

  Future<List<String>> recentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(_key) ?? <String>[];
    return records
        .map(
          (record) =>
              (jsonDecode(record) as Map<String, dynamic>)['id'] as String,
        )
        .toList();
  }

  Future<void> record(Poi poi) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];
    final record = jsonEncode({
      'id': poi.id,
      'name': poi.name,
      'category': poi.category,
      'date': DateTime.now().toIso8601String(),
    });
    final next = <String>[
      record,
      ...current.where(
        (value) => (jsonDecode(value) as Map<String, dynamic>)['id'] != poi.id,
      ),
    ].take(30).toList();
    await prefs.setStringList(_key, next);
  }

  Future<List<Map<String, dynamic>>> entries() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? <String>[])
        .map((record) => jsonDecode(record) as Map<String, dynamic>)
        .toList();
  }
}
