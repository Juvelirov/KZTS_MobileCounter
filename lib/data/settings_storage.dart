import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _keyInitialZoom = 'initial_zoom';
  static const _keyUnsavedCount = 'unsaved_count';
  static const _keyUnsavedTime = 'unsaved_time';

  static Future<void> setInitialZoom(double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyInitialZoom, zoom);
  }

  static Future<double> getInitialZoom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyInitialZoom) ?? 6.0;
  }

  // --- Логика несохраненной сессии ---
  static Future<void> setUnsavedCount(int count) async {
    if (count <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUnsavedCount, count);
    await prefs.setString(_keyUnsavedTime, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getUnsavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyUnsavedCount);
    final timeStr = prefs.getString(_keyUnsavedTime);
    if (count != null && count > 0 && timeStr != null) {
      return {'count': count, 'time': DateTime.parse(timeStr)};
    }
    return null;
  }

  static Future<void> clearUnsavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUnsavedCount);
    await prefs.remove(_keyUnsavedTime);
  }
}