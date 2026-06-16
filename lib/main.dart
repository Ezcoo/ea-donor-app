import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/data/services/every_org_api.dart';
import 'src/data/services/notification_scheduler.dart';
import 'src/data/services/preferences_store.dart';
import 'src/data/services/sfx_player.dart';
import 'src/state/donation_state.dart';
import 'src/state/settings_state.dart';

/// Composition root: every long-lived object is constructed exactly once,
/// here, and handed to the widget tree via providers. Nothing below this
/// file calls `SharedPreferences.getInstance()` or constructs a plugin —
/// widgets only ever *receive* their dependencies.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await PreferencesStore.create();
  await store.clearBoostHistory();
  final scheduler = NotificationScheduler();
  await scheduler.init();
  final sfx = SfxPlayer();
  await sfx.init();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => EveryOrgApi()),
        Provider.value(value: sfx),
        ChangeNotifierProvider(create: (_) => DonationState(store)),
        ChangeNotifierProvider(create: (_) => SettingsState(store, scheduler)),
      ],
      child: const DonorApp(),
    ),
  );
}
