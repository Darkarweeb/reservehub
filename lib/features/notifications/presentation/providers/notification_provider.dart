import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/notification_entities.dart';

/// Provider for notification preferences management.
/// Used by the business settings screen.
class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _client;

  NotificationProvider({required SupabaseClient client}) : _client = client;

  // ─── State ─────────────────────────────────────────────────────────────────

  NotificationPreferencesEntity _preferences =
      NotificationPreferencesEntity.defaults();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;

  // ─── Getters ───────────────────────────────────────────────────────────────

  NotificationPreferencesEntity get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // ─── Load Preferences ──────────────────────────────────────────────────────

  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.rpc('get_notification_preferences');
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        _preferences = NotificationPreferencesEntity.fromJson(data);
      } else {
        _error = data['message'] as String? ?? 'Failed to load preferences';
      }
    } catch (e) {
      _error = 'Failed to load notification preferences';
      AppLogger.error(
        'loadPreferences failed',
        tag: 'NotificationProvider',
        error: e,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Save Preferences ──────────────────────────────────────────────────────

  Future<Result<void>> savePreferences(
    NotificationPreferencesEntity prefs,
  ) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'upsert_notification_preferences',
        params: {
          'p_daily_summary_enabled': prefs.dailySummaryEnabled,
          'p_appointment_notifications_enabled':
              prefs.appointmentNotificationsEnabled,
          'p_new_appointment_email_enabled': prefs.newAppointmentEmailEnabled,
          'p_cancellation_email_enabled': prefs.cancellationEmailEnabled,
          'p_reminder_email_enabled': prefs.reminderEmailEnabled,
          'p_summary_recipient_email': prefs.summaryRecipientEmail,
        },
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        _preferences = prefs;
        _successMessage = 'Notification preferences saved';
        _isSaving = false;
        notifyListeners();
        return success(null);
      } else {
        final msg = data['message'] as String? ?? 'Failed to save preferences';
        _error = msg;
        _isSaving = false;
        notifyListeners();
        return failure(ServerFailure(message: msg));
      }
    } catch (e) {
      _error = 'Failed to save notification preferences';
      _isSaving = false;
      notifyListeners();
      AppLogger.error(
        'savePreferences failed',
        tag: 'NotificationProvider',
        error: e,
      );
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Update local state optimistically ─────────────────────────────────────

  void updateLocal(NotificationPreferencesEntity prefs) {
    _preferences = prefs;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
