import 'package:flutter/foundation.dart';

import '../data/services/notification_scheduler.dart';
import '../data/services/preferences_store.dart';

/// User-configurable settings: the baseline donation and the nudge cadence.
///
/// This is the only place that talks to the NotificationScheduler, so
/// "interval changed" and "notification rescheduled" can never drift apart.
class SettingsState extends ChangeNotifier {
  SettingsState(this._store, this._scheduler)
      : _baselineDollars = _store.baselineDollars,
        _nudgeInterval =
            NudgeInterval.values.asNameMap()[_store.nudgeIntervalName] ??
                NudgeInterval.off;

  final PreferencesStore _store;
  final NotificationScheduler _scheduler;

  int _baselineDollars;
  NudgeInterval _nudgeInterval;

  /// The amount the user always intends to donate, before any boosts.
  int get baselineDollars => _baselineDollars;

  NudgeInterval get nudgeInterval => _nudgeInterval;

  Future<void> setBaseline(int dollars) async {
    _baselineDollars = dollars;
    notifyListeners();
    await _store.setBaselineDollars(dollars);
  }

  Future<void> setNudgeInterval(NudgeInterval interval) async {
    _nudgeInterval = interval;
    notifyListeners();
    await _store.setNudgeIntervalName(interval.name);
    await _scheduler.scheduleNudge(interval);
  }
}
