import 'package:flutter/foundation.dart';

import '../core/donation_ladder.dart';
import '../data/services/preferences_store.dart';

/// The pledge the user is building up on the home screen.
///
/// Holds only the *boosted* portion of the pledge — the configurable
/// baseline lives in SettingsState, and the UI adds the two together.
/// Keeping the controllers ignorant of each other means either can change
/// (or be tested) without touching the other.
///
/// The list of boost amounts, in tap order, is the single source of truth:
/// the running total and the ladder rung are both derived from it. Keeping
/// the raw history means "remove last" can undo any tap exactly — including
/// repeated taps at the $10,000 ceiling, which all add the same amount and
/// so can't be told apart from the total or rung alone.
class DonationState extends ChangeNotifier {
  DonationState(this._store) : _history = _store.boostHistory;

  final PreferencesStore _store;

  /// Amount added by each boost, oldest first. The last entry is what
  /// "remove last" peels off.
  final List<int> _history;

  /// Total added through the boost button, on top of the baseline.
  int get boostedDollars => _history.fold(0, (sum, amount) => sum + amount);

  /// Current rung on the ladder (0-based): one rung per tap so far, capped
  /// at the top. Used to pick [nextBoost] and to pitch the boost sound
  /// effect to how high the user has climbed.
  int get rung => _history.length < DonationLadder.maxIndex
      ? _history.length
      : DonationLadder.maxIndex;

  /// What the boost button will add next: $1, $3, $5, $10, …
  int get nextBoost => DonationLadder.amountAt(rung);

  /// Adds [nextBoost] to the pledge and climbs one rung. At the top of
  /// the ladder further taps keep adding the $10,000 maximum.
  void boost() {
    _history.add(nextBoost);
    _persist();
    notifyListeners();
  }

  /// Undoes the most recent boost, peeling its exact amount back off the
  /// pledge and dropping a rung. A no-op once the pledge is back to nothing.
  void removeLastBoost() {
    if (_history.isEmpty) return;
    _history.removeLast();
    _persist();
    notifyListeners();
  }

  /// Back to the bottom rung with nothing boosted — used after the user
  /// completes a donation, or from the summary card.
  void reset() {
    if (_history.isEmpty) return;
    _history.clear();
    _persist();
    notifyListeners();
  }

  void _persist() {
    // Fire-and-forget: the in-memory history above is already the source of
    // truth for this session.
    _store.setBoostHistory(_history);
  }
}
