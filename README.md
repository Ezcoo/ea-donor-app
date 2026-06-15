# Donor

A cross-platform Flutter app (Android, iOS, Linux desktop, web) for building
up a donation pledge and completing it through [every.org](https://www.every.org).

## Features

- **Boost button** — a large button that adds an ever-growing amount to your
  pledge, climbing a $1 → $3 → $5 → $10 → … → $10,000 ladder.
- **Pledge summary** — baseline + boosts = total, persisted across restarts.
- **Baseline donation** — a configurable amount you always pledge (Settings).
- **Donate now** — searches every.org's charity API and opens the chosen
  charity's donation page.
- **Nudge reminders** — a repeating notification (off / every minute /
  weekly / monthly / quarterly / biannually) reminding you to finish a
  pledged donation. Intervals are plain `Duration`s scheduled via
  `periodicallyShowWithDuration`, so any cadence is possible.
- **Sound effects** — boost taps play a blip that climbs a pentatonic
  scale with the ladder rung; donate and reset have their own sounds.
  The placeholder WAVs in `assets/sfx/` are synthesized; replace the
  files (same names) to reskin the sounds. Playback goes through
  `SfxPlayer`, which silently no-ops if no audio backend is available.

## Running

```bash
flutter run -d linux    # native desktop window
flutter run -d chrome   # web
flutter run             # Android device/emulator if connected
```

The every.org API key is injected at build time so it never lands in source
control (free keys at <https://www.every.org/charity-api>):

```bash
flutter run --dart-define=EVERY_ORG_API_KEY=pk_live_your_key
```

In VS Code, add it under `toolArgs` in `.vscode/launch.json` if you want F5
runs to include it.

## Architecture

Three layers, dependencies pointing strictly downward — UI → state → data —
with pure domain logic in `core/` that anything may use:

```
lib/
├── main.dart                  Composition root: builds every service and
│                              controller ONCE, injects them via provider.
└── src/
    ├── app.dart               MaterialApp + theme.
    ├── core/                  Pure Dart, no Flutter, no I/O. Trivially
    │   ├── donation_ladder.dart   unit-testable business rules.
    │   └── money.dart
    ├── data/
    │   ├── models/charity.dart        every.org response model.
    │   └── services/                  Each service owns ONE external thing:
    │       ├── every_org_api.dart       … the HTTP API
    │       ├── preferences_store.dart    … SharedPreferences (all keys here)
    │       └── notification_scheduler.dart … the notifications plugin
    ├── state/                 ChangeNotifier controllers = the app's truth.
    │   ├── donation_state.dart    Pledge being built (boosts + ladder rung).
    │   └── settings_state.dart    Baseline + nudge interval.
    └── ui/                    Widgets only. Read state, render, dispatch.
        ├── home/home_screen.dart
        ├── home/charity_picker_sheet.dart
        └── settings/settings_screen.dart
```

### Why this shape

- **Composition root (`main.dart`)** — every long-lived object is created in
  one place and handed down. Widgets never construct services, so tests can
  swap in fakes by building the same tree with different objects
  (see `test/widget_test.dart`).
- **Provider + ChangeNotifier** — the lightest state solution that still
  separates state from widgets; also what the official Flutter docs
  recommend for apps of this size. Migrating to Riverpod/Bloc later only
  touches `state/` and the `watch`/`read` call sites.
- **Two small controllers instead of one app-state god object** —
  `DonationState` and `SettingsState` don't know about each other. The one
  derived value that needs both (total = baseline + boosts) is computed in
  the summary widget, at the leaf.
- **Platform differences live in services** — `NotificationScheduler`
  no-ops on web/Linux (the plugin can't schedule repeats there) so no
  widget ever needs a `kIsWeb` check.
- **Money is `int` dollars** — never `double`; binary floats can't represent
  decimal amounts exactly.

### Platform notes

- Repeating notifications work on **Android / iOS / macOS** only. Android
  needed three project tweaks (already done): core-library desugaring in
  `android/app/build.gradle.kts`, plus broadcast receivers and the
  `RECEIVE_BOOT_COMPLETED` permission in `AndroidManifest.xml`.
- On **web**, the every.org API call is subject to browser CORS policy; if
  it is blocked, route it through a small proxy you control.
- iOS builds require a Mac with Xcode.
