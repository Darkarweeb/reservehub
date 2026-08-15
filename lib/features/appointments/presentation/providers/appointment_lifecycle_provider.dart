import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/appointment_lifecycle_entity.dart';
import '../../domain/repositories/appointment_lifecycle_repository.dart';

/// Provider managing the appointment lifecycle state machine.
/// Handles confirm, cancel, complete, no-show, in-progress, reschedule,
/// bulk operations, detail loading, and audit history.
class AppointmentLifecycleProvider extends ChangeNotifier {
  final AppointmentLifecycleRepository _repository;

  AppointmentLifecycleProvider({
    required AppointmentLifecycleRepository repository,
  }) : _repository = repository;

  // ─── Detail state ─────────────────────────────────────────────────────────
  AppointmentDetailEntity? _detail;
  bool _detailLoading = false;
  String? _detailError;

  AppointmentDetailEntity? get detail => _detail;
  bool get detailLoading => _detailLoading;
  String? get detailError => _detailError;

  // ─── Audit history ────────────────────────────────────────────────────────
  List<AppointmentAuditEntry> _auditHistory = [];
  bool _historyLoading = false;

  List<AppointmentAuditEntry> get auditHistory =>
      List.unmodifiable(_auditHistory);
  bool get historyLoading => _historyLoading;

  // ─── Action state ─────────────────────────────────────────────────────────
  bool _isActing = false;
  String? _actionError;
  String? _actionSuccess;

  bool get isActing => _isActing;
  String? get actionError => _actionError;
  String? get actionSuccess => _actionSuccess;

  // ─── Bulk state ───────────────────────────────────────────────────────────
  bool _isBulkActing = false;
  String? _bulkError;
  String? _bulkSuccess;

  bool get isBulkActing => _isBulkActing;
  String? get bulkError => _bulkError;
  String? get bulkSuccess => _bulkSuccess;

  // ─── Reschedule state ─────────────────────────────────────────────────────
  bool _isRescheduling = false;
  String? _rescheduleError;

  bool get isRescheduling => _isRescheduling;
  String? get rescheduleError => _rescheduleError;

  // ─── Load detail ──────────────────────────────────────────────────────────

  Future<void> loadDetail(String appointmentId) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();

    final result = await _repository.getAppointmentDetail(appointmentId);
    result.fold(
      onSuccess: (detail) {
        _detail = detail;
        _detailLoading = false;
      },
      onFailure: (failure) {
        _detailError = failure.message;
        _detailLoading = false;
        AppLogger.error(
          'loadDetail failed',
          tag: 'LifecycleProvider',
          error: failure.message,
        );
      },
    );
    notifyListeners();
  }

  Future<void> loadAuditHistory(String appointmentId) async {
    _historyLoading = true;
    notifyListeners();

    final result = await _repository.getAuditHistory(appointmentId);
    result.fold(
      onSuccess: (history) {
        _auditHistory = history;
        _historyLoading = false;
      },
      onFailure: (failure) {
        _historyLoading = false;
        AppLogger.error(
          'loadAuditHistory failed',
          tag: 'LifecycleProvider',
          error: failure.message,
        );
      },
    );
    notifyListeners();
  }

  // ─── Lifecycle actions ────────────────────────────────────────────────────

  Future<bool> confirmAppointment(String id, {String? notes}) async {
    return _performAction(
      () => _repository.confirmAppointment(id, notes: notes),
      successMsg: 'Appointment confirmed.',
      reloadId: id,
    );
  }

  Future<bool> cancelAppointment(String id, {String? reason}) async {
    return _performAction(
      () => _repository.cancelAppointmentBusiness(id, reason: reason),
      successMsg: 'Appointment cancelled.',
      reloadId: id,
    );
  }

  Future<bool> completeAppointment(String id, {String? notes}) async {
    return _performAction(
      () => _repository.completeAppointment(id, notes: notes),
      successMsg: 'Appointment marked as completed.',
      reloadId: id,
    );
  }

  Future<bool> markNoShow(String id, {String? reason}) async {
    return _performAction(
      () => _repository.markNoShow(id, reason: reason),
      successMsg: 'Appointment marked as no-show.',
      reloadId: id,
    );
  }

  Future<bool> startAppointment(String id) async {
    return _performAction(
      () => _repository.startAppointment(id),
      successMsg: 'Appointment started.',
      reloadId: id,
    );
  }

  Future<RescheduleResult?> rescheduleAppointment(
    RescheduleRequest request,
  ) async {
    _isRescheduling = true;
    _rescheduleError = null;
    notifyListeners();

    final result = await _repository.rescheduleAppointment(request);
    _isRescheduling = false;

    return result.fold(
      onSuccess: (rescheduleResult) {
        _actionSuccess = 'Appointment rescheduled successfully.';
        notifyListeners();
        return rescheduleResult;
      },
      onFailure: (failure) {
        _rescheduleError = failure.message;
        notifyListeners();
        AppLogger.error(
          'rescheduleAppointment failed',
          tag: 'LifecycleProvider',
          error: failure.message,
        );
        return null;
      },
    );
  }

  // ─── Bulk operations ──────────────────────────────────────────────────────

  Future<BulkOperationResult?> bulkConfirm(List<String> ids) async {
    return _performBulk(() => _repository.bulkConfirm(ids));
  }

  Future<BulkOperationResult?> bulkCancel(
    List<String> ids, {
    String? reason,
  }) async {
    return _performBulk(() => _repository.bulkCancel(ids, reason: reason));
  }

  Future<BulkOperationResult?> bulkComplete(List<String> ids) async {
    return _performBulk(() => _repository.bulkComplete(ids));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<bool> _performAction(
    Future<dynamic> Function() action, {
    required String successMsg,
    String? reloadId,
  }) async {
    _isActing = true;
    _actionError = null;
    _actionSuccess = null;
    notifyListeners();

    final result = await action();
    _isActing = false;

    return result.fold(
      onSuccess: (_) async {
        _actionSuccess = successMsg;
        if (reloadId != null) {
          await loadDetail(reloadId);
          await loadAuditHistory(reloadId);
        }
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _actionError = failure.message;
        notifyListeners();
        AppLogger.error(
          'lifecycle action failed',
          tag: 'LifecycleProvider',
          error: failure.message,
        );
        return false;
      },
    );
  }

  Future<BulkOperationResult?> _performBulk(
    Future<dynamic> Function() action,
  ) async {
    _isBulkActing = true;
    _bulkError = null;
    _bulkSuccess = null;
    notifyListeners();

    final result = await action();
    _isBulkActing = false;

    return result.fold(
      onSuccess: (bulkResult) {
        _bulkSuccess =
            '${bulkResult.succeeded} appointment(s) updated successfully.';
        if (bulkResult.failed > 0) {
          _bulkError =
              '${bulkResult.failed} appointment(s) could not be updated.';
        }
        notifyListeners();
        return bulkResult;
      },
      onFailure: (failure) {
        _bulkError = failure.message;
        notifyListeners();
        return null;
      },
    );
  }

  void clearMessages() {
    _actionError = null;
    _actionSuccess = null;
    _bulkError = null;
    _bulkSuccess = null;
    _rescheduleError = null;
    notifyListeners();
  }

  void clearDetail() {
    _detail = null;
    _auditHistory = [];
    _detailError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
