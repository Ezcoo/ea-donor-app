import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donor_app/src/app.dart';
import 'package:donor_app/src/core/donation_ladder.dart';
import 'package:donor_app/src/data/models/charity.dart';
import 'package:donor_app/src/data/services/every_org_api.dart';
import 'package:donor_app/src/data/services/notification_scheduler.dart';
import 'package:donor_app/src/data/services/preferences_store.dart';
import 'package:donor_app/src/data/services/sfx_player.dart';
import 'package:donor_app/src/state/donation_state.dart';
import 'package:donor_app/src/state/settings_state.dart';

/// Builds the app exactly as main() does, but on top of in-memory prefs.
/// Being able to do this in four lines is the payoff of keeping all
/// wiring in the composition root.
Future<Widget> buildTestApp({Map<String, Object> initialPrefs = const {}}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final store = await PreferencesStore.create();
  await store.clearBoostHistory();
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

Future<void> pumpPastBoostAnimations(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pump();
}

void main() {
  final boostButton = find.byKey(const Key('boost-button'));

  testWidgets('boost button climbs the ladder and accumulates the pledge', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestApp());

    // First rung: the button offers $1.
    expect(find.text(r'+$1'), findsOneWidget);

    // The screen has a continuous idle heartbeat, so pump a fixed duration
    // past the finite boost animations instead of waiting for full settlement.
    await tester.tap(boostButton);
    await pumpPastBoostAnimations(tester);

    // $1 was added, the button now offers the next rung ($3).
    expect(find.text(r'+$3'), findsOneWidget);

    await tester.tap(boostButton);
    await pumpPastBoostAnimations(tester);

    // Total pledge = 1 + 3 = $4 (shown for both Boosts and the total,
    // since the default baseline is $0).
    expect(find.text(r'$4'), findsNWidgets(2));
    expect(find.text(r'+$5'), findsOneWidget);
  });

  testWidgets('reset clears boosts and returns to the bottom rung', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestApp());

    await tester.tap(boostButton);
    await pumpPastBoostAnimations(tester);
    await tester.tap(find.text('Reset boosts'));
    await tester.pump();

    // Reset now asks for confirmation; nothing changes until the user
    // commits in the dialog.
    expect(find.text(r'+$3'), findsOneWidget); // still on the second rung
    await tester.tap(find.text('Reset'));
    await pumpPastBoostAnimations(tester);

    expect(find.text(r'+$1'), findsOneWidget);
  });

  testWidgets('fresh app launch starts boost button from the bottom rung', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestApp(initialPrefs: {
      'boostHistory': ['1', '3'],
    }));

    expect(find.text(r'+$1'), findsOneWidget);
    expect(find.text(r'+$5'), findsNothing);
  });

  test('removeLastBoost peels off repeated ceiling taps one for one', () async {
    SharedPreferences.setMockInitialValues({});
    final donation = DonationState(await PreferencesStore.create());

    // Climb to the top of the ladder, then keep tapping the ceiling.
    while (donation.rung < DonationLadder.maxIndex) {
      donation.boost();
    }
    expect(donation.nextBoost, DonationLadder.steps.last); // $10,000
    final atCeiling = donation.boostedDollars;
    const extraTaps = 3;
    for (var i = 0; i < extraTaps; i++) {
      donation.boost();
    }
    expect(
      donation.boostedDollars,
      atCeiling + extraTaps * DonationLadder.steps.last,
    );

    // Each undo must remove exactly one $10,000 tap, not walk back down the
    // ladder — this is what the history tracking buys us.
    for (var remaining = extraTaps; remaining > 0; remaining--) {
      donation.removeLastBoost();
      expect(
        donation.boostedDollars,
        atCeiling + (remaining - 1) * DonationLadder.steps.last,
      );
    }
    expect(donation.boostedDollars, atCeiling);
  });

  test('Every.org donate link includes the pledge amount', () {
    final api = EveryOrgApi();
    final uri = api.donateUri(
      const Charity(
        name: 'GiveDirectly',
        profileUrl: 'https://www.every.org/givedirectly',
      ),
      amountDollars: 25,
    );

    expect(uri.toString(), 'https://www.every.org/givedirectly?amount=25#donate');
  });
}
