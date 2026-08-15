import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../features/scheduling/domain/repositories/availability_repository.dart';
import '../../domain/repositories/public_booking_repository.dart';

class PublicBookingRepositoryImpl implements PublicBookingRepository {
  final SupabaseClient _client;
  final AvailabilityRepository _availabilityRepo;

  const PublicBookingRepositoryImpl({
    required SupabaseClient client,
    required AvailabilityRepository availabilityRepo,
  }) : _client = client,
       _availabilityRepo = availabilityRepo;

  @override
  Future<Result<PublicBookingResult>> bookAppointment({
    required String businessSlug,
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime startTime,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc(
        'book_appointment',
        params: {
          'p_business_slug': businessSlug,
          'p_branch_id': branchId,
          'p_service_id': serviceId,
          'p_employee_id': employeeId,
          'p_starts_at': startTime.toUtc().toIso8601String(),
          'p_guest_name': customerName,
          'p_guest_email': customerEmail,
          'p_guest_phone': customerPhone,
          'p_notes': notes,
        },
      );

      final data = response as Map<String, dynamic>;
      final status = data['status'] as String;

      if (status != 'success') {
        final message = _mapBookingError(status, data['message'] as String?);
        return failure(ConflictFailure(message: message));
      }

      return success(
        PublicBookingResult(
          appointmentId: data['appointment_id'] as String,
          bookingToken: data['booking_token'] as String,
          cancellationToken: data['cancel_token'] as String,
          startTime: DateTime.parse(data['starts_at'] as String),
          endTime: DateTime.parse(data['ends_at'] as String),
          serviceName: serviceId,
          businessName: businessSlug,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'bookAppointment failed',
        tag: 'PublicBookingRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<AppointmentTokenResult>> getAppointmentByToken(
    String token,
  ) async {
    try {
      final response = await _client.rpc(
        'get_appointment_by_token',
        params: {'p_token': token},
      );

      final data = response as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return failure(NotFoundFailure(message: data['error'] as String));
      }

      final business = data['business'] as Map<String, dynamic>? ?? {};
      final branch = data['branch'] as Map<String, dynamic>? ?? {};
      final services = data['services'] as List<dynamic>? ?? [];
      final serviceName = services.isNotEmpty
          ? (services.first as Map<String, dynamic>)['name'] as String? ?? ''
          : '';

      return success(
        AppointmentTokenResult(
          appointmentId: data['appointment_id'] as String,
          tokenType: 'booking',
          tokenStatus: 'active',
          customerName: '',
          businessName: business['name'] as String? ?? '',
          serviceName: serviceName,
          startTime: DateTime.parse(data['starts_at'] as String),
          endTime: DateTime.parse(data['ends_at'] as String),
          status: data['status'] as String? ?? 'pending',
          branchName: branch['name'] as String?,
          branchAddress: branch['address_line1'] as String?,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'getAppointmentByToken failed',
        tag: 'PublicBookingRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> confirmAppointmentByToken(String token) async {
    try {
      final response = await _client.rpc(
        'confirm_appointment_by_token',
        params: {'p_token': token},
      );
      final data = response as Map<String, dynamic>;
      if (data.containsKey('error')) {
        return failure(ServerFailure(message: data['error'] as String));
      }
      return success(null);
    } catch (e, st) {
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> cancelAppointmentByToken(
    String token, {
    String? reason,
  }) async {
    try {
      final response = await _client.rpc(
        'cancel_appointment_by_token',
        params: {'p_cancel_token': token, 'p_reason': reason},
      );
      final data = response as Map<String, dynamic>;
      if (data.containsKey('error')) {
        return failure(ConflictFailure(message: data['error'] as String));
      }
      return success(null);
    } catch (e, st) {
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<List<DateTime>>> getAvailableSlots({
    required String businessId,
    required String serviceId,
    required String employeeId,
    required DateTime date,
  }) async {
    // Delegate to existing AvailabilityRepository
    final result = await _availabilityRepo.getPublicAvailability(
      businessSlug: businessId,
      branchId: '',
      serviceId: serviceId,
      employeeId: employeeId,
      date: date,
    );
    return result.map((slots) => slots.map((s) => s.startsAt).toList());
  }

  String _mapBookingError(String status, String? serverMessage) {
    switch (status) {
      case 'error_business_not_found':
        return 'Business not found.';
      case 'error_business_not_published':
        return 'This business is not currently accepting bookings.';
      case 'error_branch_invalid':
        return 'The selected branch is not available.';
      case 'error_service_inactive':
        return 'This service is no longer available.';
      case 'error_service_not_at_branch':
        return 'This service is not available at the selected branch.';
      case 'error_employee_inactive':
        return 'The selected staff member is not available.';
      case 'error_employee_cannot_provide_service':
        return 'The selected staff member does not provide this service.';
      case 'error_slot_unavailable':
      case 'error_double_booking':
        return 'This time slot is no longer available. Please select another time.';
      case 'error_outside_business_hours':
        return serverMessage ?? 'This time is outside business hours.';
      case 'error_employee_unavailable':
        return serverMessage ??
            'The staff member is not available at this time.';
      case 'error_capacity_exceeded':
        return 'This time slot is fully booked.';
      case 'error_invalid_datetime':
        return 'Please select a future appointment time.';
      default:
        return serverMessage ?? 'Booking failed. Please try again.';
    }
  }

  @override
  void dispose() {}
}
