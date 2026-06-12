/// The fixed progression of boost amounts: $1, $3, $5, $10, … $10,000.
///
/// A 1-3-5 pattern repeated per order of magnitude keeps every amount
/// feeling "round" while roughly doubling at each step, so the ladder
/// covers four orders of magnitude in only 13 taps.
class DonationLadder {
  const DonationLadder._(); // namespace only, never instantiated

  /// $1, $3, $5, $10, $30, $50, $100, …, $5,000, $10,000.
  static final List<int> steps = List.unmodifiable([
    for (var magnitude = 1; magnitude <= 1000; magnitude *= 10)
      for (final factor in const [1, 3, 5]) factor * magnitude,
    10000,
  ]);

  static int get maxIndex => steps.length - 1;

  static int amountAt(int index) => steps[index.clamp(0, maxIndex)];
}
