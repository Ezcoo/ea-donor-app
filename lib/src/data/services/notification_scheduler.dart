import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// How often the user is nudged to finish a pledged donation.
///
/// Each choice carries its repeat period as a plain [Duration] so the
/// scheduler can use the plugin's duration-based API — the fixed
/// RepeatInterval set (hourly/daily/weekly) cannot express monthly or
/// quarterly. `everyMinute` exists purely so the feature can be demoed
/// without waiting a week.
enum NudgeInterval {
  off(null, 'Off'),
  everyMinute(Duration(minutes: 1), 'Every minute'),
  weekly(Duration(days: 7), 'Weekly'),
  monthly(Duration(days: 30), 'Monthly'),
  quarterly(Duration(days: 91), 'Quarterly'),
  halfYear(Duration(days: 182), 'Half a year');

  const NudgeInterval(this.period, this.label);

  final Duration? period;
  final String label;
}

/// Owns the flutter_local_notifications plugin and the nudge schedule.
///
/// All platform capability checks live here so the rest of the app can
/// call [scheduleNudge] unconditionally: on web and Linux (where the
/// plugin cannot schedule repeating notifications) the call is a no-op
/// instead of a crash.
class NotificationScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// A fixed id so re-scheduling replaces the previous nudge instead of
  /// stacking up duplicates.
  static const _nudgeId = 1001;

  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<void> init() async {
    if (!_supported) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<void> scheduleNudge(NudgeInterval interval) async {
    if (!_supported) {
      debugPrint('Nudge notifications are not supported on this platform.');
      return;
    }
    await _plugin.cancel(id: _nudgeId);
    final period = interval.period;
    if (period == null) return;

    // Android 13+ requires asking at runtime; a no-op everywhere else.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin.periodicallyShowWithDuration(
      id: _nudgeId,
      title: 'Your pledge is waiting',
      body: 'You have money set aside — open Donor to finish your donation 💝',
      repeatDurationInterval: period,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'nudges',
          'Donation nudges',
          channelDescription: 'Reminders to finish a pledged donation',
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      // Inexact is deliberate: nudges don't need minute precision, and
      // exact alarms require an extra Android permission + user toggle.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
