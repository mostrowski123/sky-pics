import 'package:shared_preferences/shared_preferences.dart';

/// Manages persisted user settings (column count override).
class SettingsService {
  static const _columnKey = 'column_count_override';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  /// Returns the user's manual column override, or null for auto.
  int? get columnOverride {
    final val = _prefs.getInt(_columnKey);
    return (val != null && val > 0) ? val : null;
  }

  /// Set the column override. Pass null to revert to auto.
  Future<void> setColumnOverride(int? count) async {
    if (count == null || count <= 0) {
      await _prefs.remove(_columnKey);
    } else {
      await _prefs.setInt(_columnKey, count);
    }
  }
}
