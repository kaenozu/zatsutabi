import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/poi.dart';

/// A validated history entry. Kept as a plain value object so the UI never
/// has to defensively handle raw `Map<String, dynamic>` shapes.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
  });

  factory HistoryEntry.fromPoi(Poi poi) => HistoryEntry(
    id: poi.id,
    name: poi.name,
    category: poi.category,
    date: DateTime.now(),
  );

  final String id;
  final String name;
  final String category;
  final DateTime date;
}

class HistoryStore {
  static const _key = 'suggestion_history_v2';
  Future<void> _writeQueue = Future<void>.value();

  Future<List<String>> recentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(_key) ?? <String>[];
    return records
        .map(_decode)
        .whereType<HistoryEntry>()
        .map((entry) => entry.id)
        .toList();
  }

  Future<void> record(Poi poi) async {
    final previous = _writeQueue.catchError((_) {});
    _writeQueue = previous.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];
      final entry = HistoryEntry.fromPoi(poi);
      final encoded = jsonEncode({
        'id': entry.id,
        'name': entry.name,
        'category': entry.category,
        'date': entry.date.toIso8601String(),
      });
      final next = <String>[
        encoded,
        ...current.where((value) => _decode(value)?.id != poi.id),
      ].take(30).toList();
      await prefs.setStringList(_key, next);
    });
    await _writeQueue;
  }

  Future<List<HistoryEntry>> entries() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? <String>[])
        .map(_decode)
        .whereType<HistoryEntry>()
        .toList();
  }

  /// Strict decoder: any malformed record (wrong types, missing fields) is
  /// dropped instead of being treated as valid and crashing the UI later.
  HistoryEntry? _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final id = decoded['id'];
      final name = decoded['name'];
      final category = decoded['category'];
      final date = decoded['date'];
      if (id is! String || id.isEmpty) return null;
      if (name is! String) return null;
      if (category is! String) return null;
      final parsedDate = date is String ? DateTime.tryParse(date) : null;
      if (parsedDate == null) return null;
      return HistoryEntry(
        id: id,
        name: name,
        category: category,
        date: parsedDate,
      );
    } on Object {
      return null;
    }
  }
}
