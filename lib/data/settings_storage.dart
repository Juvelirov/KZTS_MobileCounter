import 'package:shared_preferences/shared_preferences.dart';

// Хранилище настроек приложения.
class SettingsStorage {
  static const _keyInitialZoom = 'initial_zoom';

  static Future<void> setInitialZoom(double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyInitialZoom, zoom);
  }

  static Future<double> getInitialZoom() async {
    final prefs = await SharedPreferences.getInstance();
    // 6.0x zoom - по умолчанию, если не меняли в настройках
    return prefs.getDouble(_keyInitialZoom) ?? 6.0;
  }
}