import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/public_discovery_repository.dart';

/// State for the public business discovery experience.
class PublicDiscoveryProvider extends ChangeNotifier {
  final PublicDiscoveryRepository _repo;

  PublicDiscoveryProvider({required PublicDiscoveryRepository repository})
    : _repo = repository;

  // ─── Search state ──────────────────────────────────────────────────────────
  List<PublicBusinessResult> _searchResults = [];
  bool _searchLoading = false;
  String? _searchError;
  String _lastQuery = '';
  String? _lastCity;

  // ─── Profile state ─────────────────────────────────────────────────────────
  PublicBusinessProfile? _profile;
  bool _profileLoading = false;
  String? _profileError;
  String? _loadedSlug;

  // ─── Getters ───────────────────────────────────────────────────────────────
  List<PublicBusinessResult> get searchResults =>
      List.unmodifiable(_searchResults);
  bool get searchLoading => _searchLoading;
  String? get searchError => _searchError;

  PublicBusinessProfile? get profile => _profile;
  bool get profileLoading => _profileLoading;
  String? get profileError => _profileError;

  // ─── Search ────────────────────────────────────────────────────────────────

  Future<void> search({String? query, String? city}) async {
    _lastQuery = query ?? '';
    _lastCity = city;
    _searchLoading = true;
    _searchError = null;
    notifyListeners();

    final result = await _repo.searchBusinesses(
      query: query?.isEmpty == true ? null : query,
      city: city?.isEmpty == true ? null : city,
    );

    result.fold(
      onSuccess: (results) {
        _searchResults = results;
        _searchError = null;
      },
      onFailure: (f) {
        _searchError = _friendlyError(f);
        AppLogger.error('Search failed', tag: 'PublicDiscoveryProvider');
      },
    );

    _searchLoading = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    _lastQuery = '';
    _lastCity = null;
    notifyListeners();
  }

  // ─── Profile ───────────────────────────────────────────────────────────────

  Future<void> loadProfile(String slug) async {
    if (_loadedSlug == slug && _profile != null) return;

    _profileLoading = true;
    _profileError = null;
    notifyListeners();

    final result = await _repo.getPublicBusinessProfile(slug);

    result.fold(
      onSuccess: (p) {
        _profile = p;
        _loadedSlug = slug;
        _profileError = null;
      },
      onFailure: (f) {
        _profileError = _friendlyError(f);
        _profile = null;
        AppLogger.error('Load profile failed', tag: 'PublicDiscoveryProvider');
      },
    );

    _profileLoading = false;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    _loadedSlug = null;
    _profileError = null;
    notifyListeners();
  }

  String _friendlyError(Failure f) {
    if (f is NotFoundFailure) return f.message;
    if (f is NetworkFailure) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}
