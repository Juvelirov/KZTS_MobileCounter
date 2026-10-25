import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Слой работы с локальной историей подсчетов.
class HistoryStorage {
  static const _key = 'history_records';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> add(DateTime dt, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load();
    existing.add({
      'date': _formatDate(dt),
      'time': _formatTime(dt),
      'count': count,
      'ts': dt.millisecondsSinceEpoch,
    });
    await prefs.setString(_key, jsonEncode(existing));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}