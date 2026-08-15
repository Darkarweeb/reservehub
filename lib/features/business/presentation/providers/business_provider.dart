import 'package:flutter/foundation.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../business/domain/entities/business_entity.dart';
import '../../../business/domain/repositories/business_repository.dart';

/// State for business loading.
enum BusinessStatus { initial, loading, loaded, error }

/// Provider managing the current business and its branches.
class BusinessProvider extends ChangeNotifier {
  final BusinessRepository _repository;

  BusinessStatus _status = BusinessStatus.initial;
  BusinessEntity? _currentBusiness;
  List<BusinessEntity> _businesses = [];
  List<BranchEntity> _branches = [];
  String? _errorMessage;

  BusinessProvider({required BusinessRepository repository})
    : _repository = repository;

  // ─── Getters ───────────────────────────────────────────────────────────────

  BusinessStatus get status => _status;
  BusinessEntity? get currentBusiness => _currentBusiness;
  List<BusinessEntity> get businesses => List.unmodifiable(_businesses);
  List<BranchEntity> get branches => List.unmodifiable(_branches);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == BusinessStatus.loading;
  bool get hasBusiness => _currentBusiness != null;

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadBusinesses(String organizationId) async {
    if (_status == BusinessStatus.loading) return;

    _status = BusinessStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getBusinesses(organizationId);

    result.fold(
      onSuccess: (businesses) {
        _businesses = businesses;
        if (businesses.isNotEmpty) {
          _currentBusiness = businesses.first;
        }
        _status = BusinessStatus.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _status = BusinessStatus.error;
        AppLogger.error(
          'loadBusinesses failed',
          tag: 'BizProvider',
          error: failure.message,
        );
      },
    );

    notifyListeners();
  }

  Future<void> loadBranches(String businessId) async {
    final result = await _repository.getBranches(businessId);
    result.fold(
      onSuccess: (branches) {
        _branches = branches;
        notifyListeners();
      },
      onFailure: (failure) {
        AppLogger.warning(
          'loadBranches failed: ${failure.message}',
          tag: 'BizProvider',
        );
      },
    );
  }

  Future<Result<BusinessEntity>> createBusiness(BusinessEntity business) async {
    _status = BusinessStatus.loading;
    notifyListeners();

    final result = await _repository.createBusiness(business);

    result.fold(
      onSuccess: (biz) {
        _businesses = [..._businesses, biz];
        _currentBusiness = biz;
        _status = BusinessStatus.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _status = BusinessStatus.error;
      },
    );

    notifyListeners();
    return result;
  }

  Future<Result<BusinessEntity>> updateBusiness(BusinessEntity business) async {
    final result = await _repository.updateBusiness(business);

    result.fold(
      onSuccess: (updated) {
        _businesses = _businesses
            .map((b) => b.id == updated.id ? updated : b)
            .toList();
        if (_currentBusiness?.id == updated.id) {
          _currentBusiness = updated;
        }
        notifyListeners();
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );

    return result;
  }

  Future<Result<BusinessEntity>> publishBusiness(String businessId) async {
    final result = await _repository.publishBusiness(businessId);

    result.fold(
      onSuccess: (updated) {
        _businesses = _businesses
            .map((b) => b.id == updated.id ? updated : b)
            .toList();
        if (_currentBusiness?.id == updated.id) {
          _currentBusiness = updated;
        }
        notifyListeners();
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );

    return result;
  }

  void selectBusiness(BusinessEntity business) {
    _currentBusiness = business;
    notifyListeners();
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
