import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/poi.dart';

class HistoryStore {
  static const _key = 'suggestion_history_v2';
  Future<void> _writeQueue = Future<void>.value();

  Future<List<String>> recentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(_key) ?? <String>[];
    return records
        .map(_decode)
        .whereType<Map<String, dynamic>>()
        .map((record) => record['id']! as String)
        .toList();
  }

  Future<void> record(Poi poi) async {
    final previous = _writeQueue.catchError((_) {});
    _writeQueue = previous.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];
      final encoded = jsonEncode({
        'id': poi.id,
        'name': poi.name,
        'category': poi.category,
        'date': DateTime.now().toIso8601String(),
      });
      final next = <String>[
        encoded,
        ...current.where((value) => _decode(value)?['id'] != poi.id),
      ].take(30).toList();
      await prefs.setStringList(_key, next);
    });
    await _writeQueue;
  }

  Future<List<Map<String, dynamic>>> entries() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? <String>[])
        .map(_decode)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Map<String, dynamic>? _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final record = decoded.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
      return record['id'] is String && (record['id'] as String).isNotEmpty
          ? record
          : null;
    } on Object {
      return null;
    }
  }
}
