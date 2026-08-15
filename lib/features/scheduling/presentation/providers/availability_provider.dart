import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/availability_repository.dart';

/// State for public availability queries.
class AvailabilityProvider extends ChangeNotifier {
  final AvailabilityRepository _repository;

  List<AvailabilitySlotEntity> _slots = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastQueriedDate;

  AvailabilityProvider({required AvailabilityRepository repository})
    : _repository = repository;

  List<AvailabilitySlotEntity> get slots => List.unmodifiable(_slots);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastQueriedDate => _lastQueriedDate;

  Future<void> loadAvailability({
    required String businessSlug,
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getPublicAvailability(
      businessSlug: businessSlug,
      branchId: branchId,
      serviceId: serviceId,
      employeeId: employeeId,
      date: date,
    );

    result.fold(
      onSuccess: (slots) {
        _slots = slots;
        _lastQueriedDate = date;
        _isLoading = false;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _slots = [];
        _isLoading = false;
        AppLogger.error(
          'AvailabilityProvider error',
          tag: 'AvailabilityProvider',
          error: failure.message,
        );
      },
    );

    notifyListeners();
  }

  void clearSlots() {
    _slots = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
