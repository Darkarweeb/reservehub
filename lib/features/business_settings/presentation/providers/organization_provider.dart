import 'package:flutter/foundation.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/repositories/organization_repository.dart';

/// State for organization loading.
enum OrganizationStatus { initial, loading, loaded, error }

/// Provider managing the current organization state.
class OrganizationProvider extends ChangeNotifier {
  final OrganizationRepository _repository;

  OrganizationStatus _status = OrganizationStatus.initial;
  OrganizationEntity? _organization;
  final List<OrganizationEntity> _organizations = [];
  String? _errorMessage;

  OrganizationProvider({required OrganizationRepository repository})
    : _repository = repository;

  // ─── Getters ───────────────────────────────────────────────────────────────

  OrganizationStatus get status => _status;
  OrganizationEntity? get organization => _organization;
  List<OrganizationEntity> get organizations =>
      List.unmodifiable(_organizations);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == OrganizationStatus.loading;
  bool get hasOrganization => _organization != null;

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadCurrentOrganization() async {
    if (_status == OrganizationStatus.loading) return;

    _status = OrganizationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getCurrentOrganization();

    result.fold(
      onSuccess: (org) {
        _organization = org;
        _status = OrganizationStatus.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _status = OrganizationStatus.error;
        AppLogger.error(
          'loadCurrentOrganization failed',
          tag: 'OrgProvider',
          error: failure.message,
        );
      },
    );

    notifyListeners();
  }

  Future<Result<OrganizationEntity>> createOrganization({
    required String name,
    String? email,
    String? phone,
    String? timezone,
    String? currency,
  }) async {
    _status = OrganizationStatus.loading;
    notifyListeners();

    final result = await _repository.createOrganization(
      name: name,
      email: email,
      phone: phone,
      timezone: timezone,
      currency: currency,
    );

    result.fold(
      onSuccess: (org) {
        _organization = org;
        _status = OrganizationStatus.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _status = OrganizationStatus.error;
      },
    );

    notifyListeners();
    return result;
  }

  Future<Result<OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  ) async {
    final result = await _repository.updateOrganization(organization);

    result.fold(
      onSuccess: (org) {
        _organization = org;
        notifyListeners();
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );

    return result;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
