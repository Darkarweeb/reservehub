import '../../domain/entities/organization_entity.dart';

/// Data model for [OrganizationEntity] — maps Supabase organizations table.
class OrganizationModel extends OrganizationEntity {
  const OrganizationModel({
    required super.id,
    required super.name,
    super.logoUrl,
    super.email,
    super.phone,
    super.website,
    super.address,
    super.timezone,
    super.currency,
    super.locale,
    required super.subscriptionTier,
    super.isActive,
    required super.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      timezone: json['timezone'] as String?,
      currency: json['currency'] as String?,
      locale: json['locale'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
    'email': email,
    'phone': phone,
    'website': website,
    'address': address,
    'timezone': timezone,
    'currency': currency,
    'locale': locale,
    'subscription_tier': subscriptionTier,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'logo_url': logoUrl,
    'email': email,
    'phone': phone,
    'website': website,
    'address': address,
    'timezone': timezone,
    'currency': currency,
    'locale': locale,
  };
}
