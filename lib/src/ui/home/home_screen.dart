import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../data/services/sfx_player.dart';
import '../../state/donation_state.dart';
import '../../state/settings_state.dart';
import '../settings/settings_screen.dart';
import 'charity_picker_sheet.dart';

/// Main screen: pledge summary on top, the boost button in the middle,
/// "Donate now" pinned to the bottom, all over a soft vertical gradient.
///
/// The sub-widgets are private classes in this file rather than separate
/// files: they are not reused anywhere yet, and splitting them out before
/// that happens would just scatter one screen across four files.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Donor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.65],
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.55),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SummaryCard(),
                const Expanded(child: Center(child: _BoostButton())),
                FilledButton.icon(
                  onPressed: () {
                    context.read<SfxPlayer>().donate();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => const CharityPickerSheet(),
                    );
                  },
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Donate now', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Baseline + boosts = total. Watches both controllers and derives the
/// total here, at the leaf, so the controllers stay independent.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final baseline = context.watch<SettingsState>().baselineDollars;
    final donation = context.watch<DonationState>();
    final total = baseline + donation.boostedDollars;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          children: [
            _SummaryRow(label: 'Baseline', amount: baseline),
            _SummaryRow(label: 'Boosts', amount: donation.boostedDollars),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your pledge', style: theme.textTheme.titleMedium),
                // Counts up/down to the new total instead of jumping, so
                // a boost visibly "lands" in the summary.
                TweenAnimationBuilder<double>(
                  tween: Tween(end: total.toDouble()),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedTotal, _) => Text(
                    formatDollars(animatedTotal.round()),
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: donation.boostedDollars == 0
                    ? null
                    : () {
                        context.read<SfxPlayer>().reset();
                        context.read<DonationState>().reset();
                      },
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Reset boosts'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          Text(formatDollars(amount)),
        ],
      ),
    );
  }
}

/// The big tap target. Shows the *next* boost so the user always knows
/// what a tap will do. Each press plays two animations:
///  - the button squashes and springs back (elastic scale), and
///  - the amount just added floats up out of the button and fades.
class _BoostButton extends StatefulWidget {
  const _BoostButton();

  @override
  State<_BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<_BoostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // Quick squash (25% of the time), springy recovery (75%).
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.85)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.85, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 75,
    ),
  ]).animate(_press);

  /// Bursts currently floating up; each removes itself when it finishes.
  final List<({int id, int amount})> _bursts = [];
  int _nextBurstId = 0;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _boost() {
    final donation = context.read<DonationState>();
    final amount = donation.nextBoost; // capture before boost() advances it
    context.read<SfxPlayer>().boost(donation.rung); // pitch follows the rung
    donation.boost();
    _press.forward(from: 0);
    setState(() => _bursts.add((id: _nextBurstId++, amount: amount)));
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _boost,
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                        child: Text(
                          '+${formatDollars(donation.nextBoost)}',
                          // Keyed by amount so the switcher sees a "new"
                          // child each rung and animates the swap.
                          key: ValueKey(donation.nextBoost),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      Text(
                        'boost your pledge',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final burst in _bursts)
          _FloatingBoost(
            key: ValueKey(burst.id),
            amount: burst.amount,
            seed: burst.id,
            onDone: () =>
                setState(() => _bursts.removeWhere((b) => b.id == burst.id)),
          ),
      ],
    );
  }
}

/// "+$X" drifting up from the button and fading out. A one-shot
/// TweenAnimationBuilder needs no controller; [onDone] lets the parent
/// drop the widget once it is invisible.
class _FloatingBoost extends StatelessWidget {
  const _FloatingBoost({
    super.key,
    required this.amount,
    required this.seed,
    required this.onDone,
  });

  final int amount;
  final int seed;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Deterministic horizontal scatter so rapid taps fan out a little.
    final drift = (seed % 5 - 2) * 22.0;

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        onEnd: onDone,
        builder: (context, t, _) => Transform.translate(
          offset: Offset(drift * t, -110 - 130 * t),
          child: Opacity(
            opacity: (1 - t).clamp(0, 1).toDouble(),
            child: Text(
              '+${formatDollars(amount)}',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
