import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/charity.dart';

/// Client for the every.org partner API (https://docs.every.org).
///
/// The API key is injected at build time so it never lands in source
/// control:
///
///     flutter run --dart-define=EVERY_ORG_API_KEY=pk_live_...
///
/// Free keys: https://www.every.org/charity-api
class EveryOrgApi {
  EveryOrgApi({http.Client? client}) : _client = client ?? http.Client();

  static const _apiKey = String.fromEnvironment('EVERY_ORG_API_KEY');

  final http.Client _client;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Searches nonprofits by free-text term.
  Future<List<Charity>> searchCharities(String term, {int take = 10}) async {
    if (!isConfigured) {
      throw const EveryOrgApiException(
        'No API key configured. Restart the app with '
        '--dart-define=EVERY_ORG_API_KEY=<your key>. '
        'Free keys at every.org/charity-api.',
      );
    }
    final uri = Uri.https(
      'partners.every.org',
      '/v0.2/search/${Uri.encodeComponent(term)}',
      {'apiKey': _apiKey, 'take': '$take'},
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw EveryOrgApiException(
        'Charity search failed (HTTP ${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final nonprofits = body['nonprofits'] as List<dynamic>? ?? const [];
    return [
      for (final item in nonprofits)
        Charity.fromJson(item as Map<String, dynamic>),
    ];
  }
}

/// Thrown for any failure the UI should show to the user as-is.
class EveryOrgApiException implements Exception {
  const EveryOrgApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
