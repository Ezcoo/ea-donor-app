import 'package:shared_preferences/shared_preferences.dart';

/// The single owner of all persistence keys.
///
/// Wrapping SharedPreferences buys three things: every key string lives in
/// exactly one file (no typo'd duplicates), callers get typed members
/// instead of stringly-typed lookups, and swapping the backend later
/// (e.g. to a database) touches only this class.
class PreferencesStore {
  PreferencesStore._(this._prefs);

  static Future<PreferencesStore> create() async =>
      PreferencesStore._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kBaseline = 'baselineDollars';
  static const _kBoostHistory = 'boostHistory';
  static const _kNudgeInterval = 'nudgeInterval';

  int get baselineDollars => _prefs.getInt(_kBaseline) ?? 0;
  Future<void> setBaselineDollars(int value) => _prefs.setInt(_kBaseline, value);

  /// Boost amounts in tap order. Stored as strings because
  /// SharedPreferences has no int-list type; the values are always whole
  /// dollars, so the round-trip through [int.parse] is lossless.
  List<int> get boostHistory =>
      (_prefs.getStringList(_kBoostHistory) ?? const [])
          .map(int.parse)
          .toList();
  Future<void> setBoostHistory(List<int> values) => _prefs.setStringList(
      _kBoostHistory, [for (final v in values) v.toString()]);

  String? get nudgeIntervalName => _prefs.getString(_kNudgeInterval);
  Future<void> setNudgeIntervalName(String value) =>
      _prefs.setString(_kNudgeInterval, value);
}
