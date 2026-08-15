import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';

/// Domain entity for public business search result.
class PublicBusinessResult {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? categoryName;
  final String? logoUrl;
  final String? city;
  final String? country;
  final double? rating;
  final int reviewCount;

  const PublicBusinessResult({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.categoryName,
    this.logoUrl,
    this.city,
    this.country,
    this.rating,
    this.reviewCount = 0,
  });
}

/// Domain entity for a public business profile.
class PublicBusinessProfile {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? categoryName;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? city;
  final String? country;
  final String? timezone;
  final List<PublicServiceInfo> services;
  final List<PublicBranchInfo> branches;

  const PublicBusinessProfile({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.categoryName,
    this.logoUrl,
    this.coverImageUrl,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.country,
    this.timezone,
    this.services = const [],
    this.branches = const [],
  });
}

/// Lightweight public service info for discovery.
class PublicServiceInfo {
  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String? colorHex;

  const PublicServiceInfo({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.colorHex,
  });
}

/// Lightweight public branch info.
class PublicBranchInfo {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;

  const PublicBranchInfo({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
  });
}

/// Contract for public business discovery (no auth required).
abstract interface class PublicDiscoveryRepository implements BaseRepository {
  /// Searches published businesses by name/category.
  Future<Result<List<PublicBusinessResult>>> searchBusinesses({
    String? query,
    String? categoryId,
    String? city,
    int page = 0,
    int pageSize = 20,
  });

  /// Fetches a full public business profile by slug.
  Future<Result<PublicBusinessProfile>> getPublicBusinessProfile(String slug);
}
