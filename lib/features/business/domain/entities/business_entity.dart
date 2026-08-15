/// Domain entity representing a business.
class BusinessEntity {
  final String id;
  final String organizationId;
  final String name;
  final String? slug;
  final String? description;
  final String? categoryId;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? city;
  final String? country;
  final String? timezone;
  final String publicationStatus;
  final DateTime? publishedAt;
  final bool isActive;
  final DateTime createdAt;

  const BusinessEntity({
    required this.id,
    required this.organizationId,
    required this.name,
    this.slug,
    this.description,
    this.categoryId,
    this.logoUrl,
    this.coverImageUrl,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.country,
    this.timezone,
    this.publicationStatus = 'draft',
    this.publishedAt,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isPublished => publicationStatus == 'published';
  bool get isDraft => publicationStatus == 'draft';

  BusinessEntity copyWith({
    String? name,
    String? slug,
    String? description,
    String? categoryId,
    String? logoUrl,
    String? coverImageUrl,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? country,
    String? timezone,
    String? publicationStatus,
    DateTime? publishedAt,
    bool? isActive,
  }) {
    return BusinessEntity(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      publishedAt: publishedAt ?? this.publishedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BusinessEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BusinessEntity(id: $id, name: $name, status: $publicationStatus)';
}

/// Domain entity representing a branch of a business.
class BranchEntity {
  final String id;
  final String organizationId;
  final String businessId;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? email;
  final String? timezone;
  final bool isActive;
  final DateTime createdAt;

  const BranchEntity({
    required this.id,
    required this.organizationId,
    required this.businessId,
    required this.name,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.email,
    this.timezone,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BranchEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
