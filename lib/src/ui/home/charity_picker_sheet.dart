import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/charity.dart';
import '../../data/services/every_org_api.dart';
import '../../data/services/sfx_player.dart';

/// Bottom sheet: search every.org for a charity, tap one to open its
/// donation page in the browser.
///
/// This is the one stateful widget in the app — the search term and the
/// in-flight request are *ephemeral* UI state that should die with the
/// sheet, so they live in a State object instead of a ChangeNotifier.
class CharityPickerSheet extends StatefulWidget {
  const CharityPickerSheet({super.key});

  @override
  State<CharityPickerSheet> createState() => _CharityPickerSheetState();
}

class _CharityPickerSheetState extends State<CharityPickerSheet> {
  final _searchController = TextEditingController();
  Future<List<Charity>>? _results;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;
    setState(() {
      // context.read, not watch: we want the service once, inside a
      // callback — this widget never needs to rebuild because of it.
      _results = context.read<EveryOrgApi>().searchCharities(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Keeps the text field above the on-screen keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a charity',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF06343A),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Search charities on every.org',
                  hintText: 'e.g. clean water, animals, education',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      context.read<SfxPlayer>().tap();
                      _search();
                    },
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            Expanded(
              child: _results == null
                  ? _EmptySearchState(colorScheme: theme.colorScheme)
                  : FutureBuilder<List<Charity>>(
                      future: _results,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _MessageState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Search failed',
                            message: '${snapshot.error}',
                          );
                        }
                        final charities = snapshot.requireData;
                        if (charities.isEmpty) {
                          return const _MessageState(
                            icon: Icons.search_off_outlined,
                            title: 'No results',
                            message:
                                'Try a broader cause or organization name.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                          itemCount: charities.length,
                          itemBuilder: (context, index) =>
                              _CharityTile(charity: charities[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _MessageState(
      icon: Icons.favorite_border,
      title: 'Find somewhere meaningful',
      message: 'Search by cause, place, or nonprofit name.',
      iconColor: colorScheme.primary,
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.75,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CharityTile extends StatelessWidget {
  const _CharityTile({required this.charity});

  final Charity charity;

  @override
  Widget build(BuildContext context) {
    final logoUrl = charity.logoUrl;
    final profileUrl = charity.profileUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: logoUrl == null ? null : NetworkImage(logoUrl),
          child: logoUrl == null ? const Icon(Icons.favorite_outline) : null,
        ),
        title: Text(
          charity.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        subtitle: charity.description == null
            ? null
            : Text(
                charity.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
        trailing: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.open_in_new,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: profileUrl == null
            ? null
            : () {
                context.read<SfxPlayer>().tap();
                launchUrl(Uri.parse(profileUrl));
              },
      ),
    );
  }
}
