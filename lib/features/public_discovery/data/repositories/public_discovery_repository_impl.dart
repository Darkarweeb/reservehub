import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/public_discovery_repository.dart';

class PublicDiscoveryRepositoryImpl implements PublicDiscoveryRepository {
  final SupabaseClient _client;

  const PublicDiscoveryRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<List<PublicBusinessResult>>> searchBusinesses({
    String? query,
    String? categoryId,
    String? city,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.rpc(
        'search_public_businesses',
        params: {
          'p_query': query,
          'p_category': categoryId,
          'p_city': city,
          'p_limit': pageSize,
          'p_offset': page * pageSize,
        },
      );

      final rows = response as List<dynamic>? ?? [];
      final results = rows
          .map((r) => _mapSearchResult(r as Map<String, dynamic>))
          .toList();
      return success(results);
    } catch (e, st) {
      AppLogger.error(
        'searchBusinesses failed',
        tag: 'PublicDiscoveryRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<PublicBusinessProfile>> getPublicBusinessProfile(
    String slug,
  ) async {
    try {
      final response = await _client.rpc(
        'get_public_business_profile',
        params: {'p_slug': slug},
      );

      if (response == null) {
        return failure(
          const NotFoundFailure(
            message: 'Business not found or not published.',
          ),
        );
      }

      final data = response as Map<String, dynamic>;
      final profile = _mapProfile(data);
      return success(profile);
    } catch (e, st) {
      AppLogger.error(
        'getPublicBusinessProfile failed',
        tag: 'PublicDiscoveryRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  PublicBusinessResult _mapSearchResult(Map<String, dynamic> r) {
    return PublicBusinessResult(
      id: r['id'] as String,
      name: r['name'] as String,
      slug: r['slug'] as String,
      description: r['description'] as String?,
      categoryName: r['category'] as String?,
      logoUrl: r['logo_url'] as String?,
      city: r['city'] as String?,
      country: r['country'] as String?,
    );
  }

  PublicBusinessProfile _mapProfile(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    final city = address?['city'] as String?;
    final country = address?['country'] as String?;
    final addressLine1 = address?['line1'] as String?;

    final branchesRaw = data['branches'] as List<dynamic>? ?? [];
    final servicesRaw = data['services'] as List<dynamic>? ?? [];

    return PublicBusinessProfile(
      id: data['id'] as String,
      name: data['name'] as String,
      slug: data['slug'] as String,
      description: data['description'] as String?,
      categoryName: data['category'] as String?,
      logoUrl: data['logo_url'] as String?,
      coverImageUrl: data['cover_url'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      address: addressLine1,
      city: city,
      country: country,
      timezone: data['timezone'] as String?,
      branches: branchesRaw
          .map((b) => _mapBranch(b as Map<String, dynamic>))
          .toList(),
      services: servicesRaw
          .map((s) => _mapService(s as Map<String, dynamic>))
          .toList(),
    );
  }

  PublicBranchInfo _mapBranch(Map<String, dynamic> b) {
    final addr = b['address'] as Map<String, dynamic>?;
    return PublicBranchInfo(
      id: b['id'] as String,
      name: b['name'] as String,
      address: addr?['line1'] as String?,
      city: addr?['city'] as String?,
      phone: b['phone'] as String?,
    );
  }

  PublicServiceInfo _mapService(Map<String, dynamic> s) {
    return PublicServiceInfo(
      id: s['id'] as String,
      name: s['name'] as String,
      description: s['description'] as String?,
      durationMinutes: (s['duration_mins'] as num?)?.toInt() ?? 60,
      price: (s['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void dispose() {}
}
