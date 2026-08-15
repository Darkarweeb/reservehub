/// Domain entity representing an organization (top-level tenant).
class OrganizationEntity {
  final String id;
  final String name;
  final String? logoUrl;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? timezone;
  final String? currency;
  final String? locale;
  final String subscriptionTier;
  final bool isActive;
  final DateTime createdAt;

  const OrganizationEntity({
    required this.id,
    required this.name,
    this.logoUrl,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.timezone,
    this.currency,
    this.locale,
    required this.subscriptionTier,
    this.isActive = true,
    required this.createdAt,
  });

  OrganizationEntity copyWith({
    String? name,
    String? logoUrl,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? timezone,
    String? currency,
    String? locale,
    String? subscriptionTier,
    bool? isActive,
  }) {
    return OrganizationEntity(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OrganizationEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
