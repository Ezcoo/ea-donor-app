import 'dart:math' as math;

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
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Donor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.46, 1],
            colors: [
              const Color(0xFFE1F7FA),
              colorScheme.primaryContainer.withValues(alpha: 0.45),
              const Color(0xFFF7FCFD),
            ],
          ),
        ),
        child: SafeArea(
          child: _AmbientSweepScope(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Pill(
                          icon: Icons.favorite,
                          label: 'Mindful giving, ready when you are',
                        ),
                        const SizedBox(height: 12),
                        _AmbientSweepText(
                          'Build a pledge that feels generous.',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF06343A),
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SummaryCard(),
                  const Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _BoostButton(),
                      ),
                    ),
                  ),
                  _SweepingDonateButton(
                    onPressed: () {
                      context.read<SfxPlayer>().donate();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => const CharityPickerSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepingDonateButton extends StatelessWidget {
  const _SweepingDonateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ambientSweep = _AmbientSweepScope.maybeOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Donate now', style: TextStyle(fontSize: 18)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 17),
              child: SizedBox(width: double.infinity),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: ambientSweep ?? kAlwaysDismissedAnimation,
                    builder: (context, _) {
                      final sweepValue = ambientSweep?.value ?? 1.0;
                      final activeT = (sweepValue / 0.42).clamp(0.0, 1.0);
                      final sweepProgress = Curves.easeInOutCubic.transform(
                        activeT,
                      );
                      final sweepStrength =
                          math.sin(activeT * math.pi).clamp(0.0, 1.0) * 0.58;

                      return FractionalTranslation(
                        translation: Offset(-1.15 + sweepProgress * 2.3, 0),
                        child: Opacity(
                          opacity: sweepStrength,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.transparent,
                                  const Color(
                                    0xFF42C5D6,
                                  ).withValues(alpha: 0.10),
                                  Colors.white.withValues(alpha: 0.36),
                                  const Color(
                                    0xFFBFF8FF,
                                  ).withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.30, 0.50, 0.70, 1],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientSweepScope extends StatefulWidget {
  const _AmbientSweepScope({required this.child});

  final Widget child;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AmbientSweepInherited>()
        ?.animation;
  }

  @override
  State<_AmbientSweepScope> createState() => _AmbientSweepScopeState();
}

class _AmbientSweepScopeState extends State<_AmbientSweepScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AmbientSweepInherited(animation: _sweep, child: widget.child);
  }
}

class _AmbientSweepInherited extends InheritedNotifier<Animation<double>> {
  const _AmbientSweepInherited({
    required Animation<double> animation,
    required super.child,
  }) : super(notifier: animation);

  Animation<double> get animation => notifier!;
}

class _AmbientSweepText extends StatelessWidget {
  const _AmbientSweepText(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final sweep = _AmbientSweepScope.maybeOf(context);
    final baseColor = style?.color ?? const Color(0xFF06343A);
    const sweepColor = Color(0xFF42C5D6);

    return AnimatedBuilder(
      animation: sweep ?? kAlwaysDismissedAnimation,
      builder: (context, _) {
        final sweepValue = sweep?.value ?? 1.0;
        final activeT = (sweepValue / 0.42).clamp(0.0, 1.0);
        final sweepProgress = Curves.easeInOutCubic.transform(activeT);
        final sweepStrength =
            math.sin(activeT * math.pi).clamp(0.0, 1.0) * 0.58;
        final shoulderColor = Color.lerp(
          baseColor,
          sweepColor,
          0.34 * sweepStrength,
        )!;
        final centerColor = Color.lerp(
          baseColor,
          Colors.white,
          0.62 * sweepStrength,
        )!;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final sweepWidth = bounds.width * 1.15;
            final left =
                bounds.left -
                sweepWidth +
                sweepProgress * (bounds.width + sweepWidth * 2);

            return LinearGradient(
              colors: [
                baseColor,
                baseColor,
                shoulderColor,
                centerColor,
                shoulderColor,
                baseColor,
                baseColor,
              ],
              stops: const [0, 0.20, 0.38, 0.50, 0.62, 0.80, 1],
            ).createShader(
              Rect.fromLTWH(left, bounds.top, sweepWidth, bounds.height),
            );
          },
          child: Text(text, style: style?.copyWith(color: Colors.white)),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baseline + boosts = total. Watches both controllers and derives the
/// total here, at the leaf, so the controllers stay independent.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  /// Resetting wipes every boost the user has stacked up, so confirm first.
  Future<void> _confirmReset(BuildContext context) async {
    // Capture before the await so we don't touch a stale context after it.
    final donation = context.read<DonationState>();
    final sfx = context.read<SfxPlayer>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset boosts?'),
        content: const Text(
          'This clears every boost you have added. Your baseline is '
          'unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      sfx.reset();
      donation.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseline = context.watch<SettingsState>().baselineDollars;
    final donation = context.watch<DonationState>();
    final total = baseline + donation.boostedDollars;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.savings_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pledge stack',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Baseline plus the boosts you add today',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SummaryRow(label: 'Baseline', amount: baseline),
              _SummaryRow(label: 'Boosts', amount: donation.boostedDollars),
              Divider(
                height: 20,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your pledge',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  _PledgeTotal(amount: total),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: donation.boostedDollars == 0
                        ? null
                        : () => _confirmReset(context),
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Reset boosts'),
                  ),
                  TextButton.icon(
                    onPressed: donation.boostedDollars == 0
                        ? null
                        : () {
                            final state = context.read<DonationState>();
                            state.removeLastBoost();
                            // Blip pitched to the rung we stepped back to, so
                            // undoing descends the scale that boosting climbed.
                            context.read<SfxPlayer>().boost(state.rung);
                          },
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Remove last'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PledgeTotal extends StatefulWidget {
  const _PledgeTotal({required this.amount});

  final int amount;

  @override
  State<_PledgeTotal> createState() => _PledgeTotalState();
}

class _PledgeTotalState extends State<_PledgeTotal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  late final Animation<double> _glowAmount = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 65,
    ),
  ]).animate(_glow);

  @override
  void didUpdateWidget(covariant _PledgeTotal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount > oldWidget.amount) {
      _glow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Counts up/down to the new total instead of jumping, so a boost visibly
    // "lands" in the summary.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.amount.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedTotal, _) => AnimatedBuilder(
        animation: _glowAmount,
        builder: (context, _) {
          final glow = _glowAmount.value;
          const sweepDelay = 0.08;
          final delayedSweep = ((_glow.value - sweepDelay) / (1 - sweepDelay))
              .clamp(0.0, 1.0);
          final sweepProgress = Curves.easeOutQuart.transform(delayedSweep);
          final color = theme.colorScheme.primary;
          const sweepColor = Color(0xFF42C5D6);
          final totalText = formatDollars(animatedTotal.round());
          final totalStyle = theme.textTheme.headlineMedium!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          );
          final edgeColor = color;
          final shoulderColor = Color.lerp(color, sweepColor, 0.42)!;
          final centerColor = Color.lerp(color, Colors.white, 0.74)!;

          return Transform.scale(
            scale: 1 + glow * 0.024,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  final sweepWidth = bounds.width * 1.65;
                  final left =
                      bounds.left -
                      sweepWidth +
                      sweepProgress * (bounds.width + sweepWidth * 2);

                  return LinearGradient(
                    colors: [
                      edgeColor,
                      edgeColor,
                      shoulderColor,
                      centerColor,
                      shoulderColor,
                      edgeColor,
                      edgeColor,
                    ],
                    stops: const [0, 0.20, 0.38, 0.50, 0.62, 0.80, 1],
                  ).createShader(
                    Rect.fromLTWH(left, bounds.top, sweepWidth, bounds.height),
                  );
                },
                child: Text(totalText, style: totalStyle),
              ),
            ),
          );
        },
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
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            formatDollars(amount),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
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
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _heartbeat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  // Quick squash (25% of the time), springy recovery (75%).
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.85,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 75,
    ),
  ]).animate(_press);

  late final Animation<double> _idleScale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 48),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.024,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.024,
        end: 0.996,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.996,
        end: 1.014,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.014,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
  ]).animate(_heartbeat);

  /// Bursts currently floating up; each removes itself when it finishes.
  final List<({int id, int amount})> _bursts = [];
  int _nextBurstId = 0;

  @override
  void dispose() {
    _press.dispose();
    _heartbeat.dispose();
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
    final theme = Theme.of(context);
    final ambientSweep = _AmbientSweepScope.maybeOf(context);
    const heartTop = Color(0xFF00A6BD);
    const heartBottom = Color(0xFF006B80);

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  heartBottom.withValues(alpha: 0.22),
                  heartBottom.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_press, _heartbeat, ?ambientSweep]),
            builder: (context, _) {
              final scale = _press.isAnimating
                  ? _scale.value
                  : _idleScale.value;
              final sweepValue = ambientSweep?.value ?? 1.0;
              final activeT = (sweepValue / 0.42).clamp(0.0, 1.0);
              final sweepProgress = Curves.easeInOutCubic.transform(activeT);
              final sweepStrength =
                  math.sin(activeT * math.pi).clamp(0.0, 1.0) * 0.68;

              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 250,
                  height: 230,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: const _HeartBorder(),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [heartTop, heartBottom],
                            ),
                            shadows: [
                              BoxShadow(
                                color: heartBottom.withValues(alpha: 0.36),
                                blurRadius: 42,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ClipPath(
                            clipper: const _HeartClipper(),
                            child: FractionalTranslation(
                              translation: Offset(
                                -1.25 + sweepProgress * 2.5,
                                0,
                              ),
                              child: Opacity(
                                opacity: sweepStrength,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.transparent,
                                        const Color(
                                          0xFF42C5D6,
                                        ).withValues(alpha: 0.12),
                                        Colors.white.withValues(alpha: 0.44),
                                        const Color(
                                          0xFFBFF8FF,
                                        ).withValues(alpha: 0.20),
                                        Colors.transparent,
                                      ],
                                      stops: const [0, 0.30, 0.50, 0.70, 1],
                                    ),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        shape: const _HeartBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('boost-button'),
                          customBorder: const _HeartBorder(),
                          onTap: _boost,
                          child: Center(
                            child: Transform.translate(
                              offset: const Offset(0, -8),
                              child: SizedBox(
                                width: 184,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          ScaleTransition(
                                            scale: animation,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          ),
                                      child: SizedBox(
                                        key: ValueKey(donation.nextBoost),
                                        width: 184,
                                        height: 58,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '+${formatDollars(donation.nextBoost)}',
                                            style: TextStyle(
                                              fontSize: 43,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'boost your pledge',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.84,
                                            ),
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          for (final burst in _bursts)
            for (var i = 0; i < 5; i++)
              _FloatingHeart(
                key: ValueKey('heart-${burst.id}-$i'),
                seed: burst.id * 5 + i,
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
      ),
    );
  }
}

class _HeartBorder extends ShapeBorder {
  const _HeartBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(8), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final left = rect.left;
    final top = rect.top;

    return Path()
      ..moveTo(left + width * 0.50, top + height * 0.92)
      ..cubicTo(
        left + width * 0.18,
        top + height * 0.72,
        left,
        top + height * 0.52,
        left,
        top + height * 0.30,
      )
      ..cubicTo(
        left,
        top + height * 0.10,
        left + width * 0.16,
        top,
        left + width * 0.32,
        top,
      )
      ..cubicTo(
        left + width * 0.42,
        top,
        left + width * 0.49,
        top + height * 0.07,
        left + width * 0.50,
        top + height * 0.17,
      )
      ..cubicTo(
        left + width * 0.51,
        top + height * 0.07,
        left + width * 0.58,
        top,
        left + width * 0.68,
        top,
      )
      ..cubicTo(
        left + width * 0.84,
        top,
        left + width,
        top + height * 0.10,
        left + width,
        top + height * 0.30,
      )
      ..cubicTo(
        left + width,
        top + height * 0.52,
        left + width * 0.82,
        top + height * 0.72,
        left + width * 0.50,
        top + height * 0.92,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => const _HeartBorder();
}

class _HeartClipper extends CustomClipper<Path> {
  const _HeartClipper();

  @override
  Path getClip(Size size) =>
      const _HeartBorder().getOuterPath(Offset.zero & size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FloatingHeart extends StatelessWidget {
  const _FloatingHeart({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF006B80),
      Color(0xFF008EA8),
      Color(0xFF00A6BD),
      Color(0xFF00B8CE),
    ];
    final direction = seed.isEven ? 1.0 : -1.0;
    final drift = direction * (78.0 + (seed % 4) * 22.0);
    final lift = 138.0 + (seed % 3) * 34.0;
    final startX = direction * (42.0 + (seed % 3) * 18.0);
    final startY = -14.0 - (seed % 2) * 16.0;
    final size = 21.0 + (seed % 3) * 5.0;
    final rotation = direction * (0.30 + (seed % 3) * 0.12);
    final delay = (seed % 4) * 0.045;
    final wobble = 4.0 + (seed % 4) * 1.5;
    final frequency = 0.95 + (seed % 3) * 0.18;
    final phase = seed * 0.9;
    final flutter = 0.045 + (seed % 3) * 0.018;

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1350),
        curve: Curves.easeOutCubic,
        builder: (context, rawT, _) {
          final t = ((rawT - delay) / (1 - delay)).clamp(0.0, 1.0);
          final opacity = (1 - t * 0.78).clamp(0.0, 1.0);
          final scale = 0.68 + Curves.easeOutBack.transform(t) * 0.32;
          final wave = math.sin((t * math.pi * 2 * frequency) + phase);
          final fadingWobble = wave * wobble * (1 - t * 0.22);
          final flutterAngle = math.sin((t * math.pi * 2.6) + phase) * flutter;

          return Transform.translate(
            offset: Offset(
              startX + drift * t + fadingWobble,
              startY - lift * t,
            ),
            child: Transform.rotate(
              angle: rotation * t + flutterAngle,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: size + 5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      Icon(
                        Icons.favorite,
                        size: size,
                        color: colors[seed % colors.length],
                        shadows: [
                          Shadow(
                            color: const Color(
                              0xFF06343A,
                            ).withValues(alpha: 0.24),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
