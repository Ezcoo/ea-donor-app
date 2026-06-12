import 'package:flutter/foundation.dart';

import '../core/donation_ladder.dart';
import '../data/services/preferences_store.dart';

/// The pledge the user is building up on the home screen.
///
/// Holds only the *boosted* portion of the pledge — the configurable
/// baseline lives in SettingsState, and the UI adds the two together.
/// Keeping the controllers ignorant of each other means either can change
/// (or be tested) without touching the other.
class DonationState extends ChangeNotifier {
  DonationState(this._store)
      : _boostedDollars = _store.boostedDollars,
        _ladderIndex = _store.ladderIndex;

  final PreferencesStore _store;

  int _boostedDollars;
  int _ladderIndex;

  /// Total added through the boost button, on top of the baseline.
  int get boostedDollars => _boostedDollars;

  /// What the boost button will add next: $1, $3, $5, $10, …
  int get nextBoost => DonationLadder.amountAt(_ladderIndex);

  /// Adds [nextBoost] to the pledge and climbs one rung. At the top of
  /// the ladder further taps keep adding the $10,000 maximum.
  void boost() {
    _boostedDollars += nextBoost;
    if (_ladderIndex < DonationLadder.maxIndex) _ladderIndex++;
    _persist();
    notifyListeners();
  }

  /// Back to the bottom rung with nothing boosted — used after the user
  /// completes a donation, or from the summary card.
  void reset() {
    _boostedDollars = 0;
    _ladderIndex = 0;
    _persist();
    notifyListeners();
  }

  void _persist() {
    // Fire-and-forget: prefs writes are atomic per key and the in-memory
    // values above are already the source of truth for this session.
    _store.setBoostedDollars(_boostedDollars);
    _store.setLadderIndex(_ladderIndex);
  }
}
