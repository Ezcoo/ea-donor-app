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
  static const _kBoosted = 'boostedDollars';
  static const _kLadderIndex = 'ladderIndex';
  static const _kNudgeInterval = 'nudgeInterval';

  int get baselineDollars => _prefs.getInt(_kBaseline) ?? 0;
  Future<void> setBaselineDollars(int value) => _prefs.setInt(_kBaseline, value);

  int get boostedDollars => _prefs.getInt(_kBoosted) ?? 0;
  Future<void> setBoostedDollars(int value) => _prefs.setInt(_kBoosted, value);

  int get ladderIndex => _prefs.getInt(_kLadderIndex) ?? 0;
  Future<void> setLadderIndex(int value) => _prefs.setInt(_kLadderIndex, value);

  String? get nudgeIntervalName => _prefs.getString(_kNudgeInterval);
  Future<void> setNudgeIntervalName(String value) =>
      _prefs.setString(_kNudgeInterval, value);
}
