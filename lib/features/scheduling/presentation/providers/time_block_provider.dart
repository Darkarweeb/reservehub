import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/time_block_repository.dart';

/// State for administrative time block management.
class TimeBlockProvider extends ChangeNotifier {
  final TimeBlockRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  TimeBlockProvider({required TimeBlockRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> createBlock({
    required String branchId,
    required String title,
    required DateTime blockDate,
    required String startTime,
    required String endTime,
    String? employeeId,
    String? reason,
    bool isAllDay = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.createTimeBlock(
      branchId: branchId,
      title: title,
      blockDate: blockDate,
      startTime: startTime,
      endTime: endTime,
      employeeId: employeeId,
      reason: reason,
      isAllDay: isAllDay,
    );

    _isLoading = false;

    return result.fold(
      onSuccess: (_) {
        _successMessage = 'Time block created.';
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        AppLogger.error(
          'createBlock error',
          tag: 'TimeBlockProvider',
          error: failure.message,
        );
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> updateBlock({
    required String blockId,
    String? title,
    DateTime? blockDate,
    String? startTime,
    String? endTime,
    String? reason,
    bool? isAllDay,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateTimeBlock(
      blockId: blockId,
      title: title,
      blockDate: blockDate,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
      isAllDay: isAllDay,
    );

    _isLoading = false;

    return result.fold(
      onSuccess: (_) {
        _successMessage = 'Time block updated.';
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> deleteBlock(String blockId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.deleteTimeBlock(blockId);

    _isLoading = false;

    return result.fold(
      onSuccess: (_) {
        _successMessage = 'Time block removed.';
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
