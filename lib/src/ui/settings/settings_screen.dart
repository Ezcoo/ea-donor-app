import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            icon: Icons.savings_outlined,
            title: 'Baseline donation',
            subtitle: 'The amount you always pledge, before any boosts.',
            child: TextField(
              controller: _baselineController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: r'$ ',
                labelText: 'Amount in dollars',
                border: OutlineInputBorder(),
              ),
              onChanged: _saveBaseline,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            icon: Icons.notifications_active_outlined,
            title: 'Nudge reminders',
            subtitle: 'How often to remind you to finish a pledged '
                'donation. Works on Android, iOS and macOS.',
            child: RadioGroup<NudgeInterval>(
              groupValue: settings.nudgeInterval,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsState>().setNudgeInterval(value);
                }
              },
              child: Column(
                children: [
                  for (final interval in NudgeInterval.values)
                    RadioListTile<NudgeInterval>(
                      value: interval,
                      title: Text(interval.label),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Donor · pledge first, give when ready',
              style: theme.textTheme.bodySmall!
                  .copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall!
                  .copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
