import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/charity.dart';
import '../../data/services/every_org_api.dart';

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
    return Padding(
      // Keeps the text field above the on-screen keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Search charities on every.org',
                  hintText: 'e.g. clean water, animals, education',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            Expanded(
              child: _results == null
                  ? const Center(child: Text('Find a charity to donate to'))
                  : FutureBuilder<List<Charity>>(
                      future: _results,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final charities = snapshot.requireData;
                        if (charities.isEmpty) {
                          return const Center(child: Text('No results'));
                        }
                        return ListView.builder(
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

class _CharityTile extends StatelessWidget {
  const _CharityTile({required this.charity});

  final Charity charity;

  @override
  Widget build(BuildContext context) {
    final logoUrl = charity.logoUrl;
    final profileUrl = charity.profileUrl;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: logoUrl == null ? null : NetworkImage(logoUrl),
        child: logoUrl == null ? const Icon(Icons.favorite_outline) : null,
      ),
      title: Text(charity.name),
      subtitle: charity.description == null
          ? null
          : Text(
              charity.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: profileUrl == null
          ? null
          : () => launchUrl(Uri.parse(profileUrl)),
    );
  }
}
