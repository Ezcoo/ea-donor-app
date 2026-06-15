import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/services/sfx_player.dart';
import '../../data/services/notification_scheduler.dart';
import '../../state/settings_state.dart';

/// Baseline donation amount and nudge-notification cadence.
///
/// Stateful only because the baseline text field needs a controller with
/// the right lifecycle; the actual settings still live in SettingsState.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _baselineController;

  @override
  void initState() {
    super.initState();
    // read, not watch: we only need the initial value. The field itself
    // is the source of truth while the user is typing.
    _baselineController = TextEditingController(
      text: context.read<SettingsState>().baselineDollars.toString(),
    );
  }

  @override
  void dispose() {
    _baselineController.dispose();
    super.dispose();
  }

  void _saveBaseline(String text) {
    // digitsOnly formatter guarantees text is empty or a positive int.
    context.read<SettingsState>().setBaseline(int.tryParse(text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1F7FA), Color(0xFFF7FCFD)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Tune your pledge rhythm.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                color: const Color(0xFF06343A),
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              icon: Icons.savings_outlined,
              title: 'Baseline donation',
              subtitle: 'Your default pledge before boosts.',
              child: TextField(
                controller: _baselineController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: r'$ ',
                  labelText: 'Amount in dollars',
                ),
                onChanged: _saveBaseline,
              ),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              icon: Icons.notifications_active_outlined,
              title: 'Nudge reminders',
              subtitle: 'How often to remind you to finish a pledge.',
              child: RadioGroup<NudgeInterval>(
                groupValue: settings.nudgeInterval,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SfxPlayer>().tap();
                    context.read<SettingsState>().setNudgeInterval(value);
                  }
                },
                child: Column(
                  children: [
                    for (final interval in NudgeInterval.values)
                      _NudgeOption(interval: interval),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Donor · pledge first, give when ready',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled card so each setting reads as one visual unit.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontSize: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NudgeOption extends StatelessWidget {
  const _NudgeOption({required this.interval});

  final NudgeInterval interval;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<NudgeInterval>(
      value: interval,
      title: Text(
        interval.label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
