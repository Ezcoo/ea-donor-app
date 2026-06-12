import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donor_app/src/app.dart';
import 'package:donor_app/src/data/services/every_org_api.dart';
import 'package:donor_app/src/data/services/notification_scheduler.dart';
import 'package:donor_app/src/data/services/preferences_store.dart';
import 'package:donor_app/src/data/services/sfx_player.dart';
import 'package:donor_app/src/state/donation_state.dart';
import 'package:donor_app/src/state/settings_state.dart';

/// Builds the app exactly as main() does, but on top of in-memory prefs.
/// Being able to do this in four lines is the payoff of keeping all
/// wiring in the composition root.
Future<Widget> buildTestApp() async {
  SharedPreferences.setMockInitialValues({});
  final store = await PreferencesStore.create();
  return MultiProvider(
    providers: [
      Provider(create: (_) => EveryOrgApi()),
      // init() is deliberately not called: the play methods no-op when no
      // pools were loaded, so tests run silently without the plugin.
      Provider(create: (_) => SfxPlayer()),
      ChangeNotifierProvider(create: (_) => DonationState(store)),
      ChangeNotifierProvider(
        create: (_) => SettingsState(store, NotificationScheduler()),
      ),
    ],
    child: const DonorApp(),
  );
}

void main() {
  testWidgets('boost button climbs the ladder and accumulates the pledge',
      (tester) async {
    await tester.pumpWidget(await buildTestApp());

    // First rung: the button offers $1.
    expect(find.text(r'+$1'), findsOneWidget);

    // pumpAndSettle, not pump: each boost plays finite animations (button
    // spring, floating "+$X", total count-up) that must finish before the
    // resting state can be asserted.
    await tester.tap(find.text(r'+$1'));
    await tester.pumpAndSettle();

    // $1 was added, the button now offers the next rung ($3).
    expect(find.text(r'+$3'), findsOneWidget);

    await tester.tap(find.text(r'+$3'));
    await tester.pumpAndSettle();

    // Total pledge = 1 + 3 = $4 (shown for both Boosts and the total,
    // since the default baseline is $0).
    expect(find.text(r'$4'), findsNWidgets(2));
    expect(find.text(r'+$5'), findsOneWidget);
  });

  testWidgets('reset clears boosts and returns to the bottom rung',
      (tester) async {
    await tester.pumpWidget(await buildTestApp());

    await tester.tap(find.text(r'+$1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset boosts'));
    await tester.pumpAndSettle();

    expect(find.text(r'+$1'), findsOneWidget);
  });
}
