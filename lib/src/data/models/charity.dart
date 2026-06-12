/// One nonprofit as returned by the every.org search API.
///
/// Only `name` is guaranteed; everything else is nullable because the API
/// omits fields for some nonprofits, and a missing logo or description
/// should degrade gracefully in the UI rather than crash JSON parsing.
class Charity {
  const Charity({
    required this.name,
    this.description,
    this.ein,
    this.logoUrl,
    this.profileUrl,
  });

  factory Charity.fromJson(Map<String, dynamic> json) => Charity(
        name: json['name'] as String? ?? 'Unknown charity',
        description: json['description'] as String?,
        ein: json['ein'] as String?,
        logoUrl: json['logoUrl'] as String?,
        profileUrl: json['profileUrl'] as String?,
      );

  final String name;
  final String? description;
  final String? ein;
  final String? logoUrl;
  final String? profileUrl;
}
