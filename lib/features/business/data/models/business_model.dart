import '../../../business/domain/entities/business_entity.dart';

/// Data model for [BusinessEntity] — maps Supabase businesses table.
class BusinessModel extends BusinessEntity {
  const BusinessModel({
    required super.id,
    required super.organizationId,
    required super.name,
    super.slug,
    super.description,
    super.categoryId,
    super.logoUrl,
    super.coverImageUrl,
    super.email,
    super.phone,
    super.website,
    super.address,
    super.city,
    super.country,
    super.timezone,
    super.publicationStatus,
    super.publishedAt,
    super.isActive,
    required super.createdAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      timezone: json['timezone'] as String?,
      publicationStatus: json['publication_status'] as String? ?? 'draft',
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'name': name,
    'slug': slug,
    'description': description,
    'category_id': categoryId,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'email': email,
    'phone': phone,
    'website': website,
    'address': address,
    'city': city,
    'country': country,
    'timezone': timezone,
    'publication_status': publicationStatus,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toInsertJson() => {
    'organization_id': organizationId,
    'name': name,
    'slug': slug,
    'description': description,
    'category_id': categoryId,
    'timezone': timezone,
    'email': email,
    'phone': phone,
    'address': address,
    'city': city,
    'country': country,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'slug': slug,
    'description': description,
    'category_id': categoryId,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'email': email,
    'phone': phone,
    'website': website,
    'address': address,
    'city': city,
    'country': country,
    'timezone': timezone,
  };
}

/// Data model for [BranchEntity].
class BranchModel extends BranchEntity {
  const BranchModel({
    required super.id,
    required super.organizationId,
    required super.businessId,
    required super.name,
    super.address,
    super.city,
    super.country,
    super.phone,
    super.email,
    super.timezone,
    super.isActive,
    required super.createdAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      timezone: json['timezone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'business_id': businessId,
    'name': name,
    'address': address,
    'city': city,
    'country': country,
    'phone': phone,
    'email': email,
    'timezone': timezone,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}
