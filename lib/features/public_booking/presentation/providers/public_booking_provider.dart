import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../features/scheduling/domain/repositories/availability_repository.dart';
import '../../domain/repositories/public_booking_repository.dart';

/// Booking step enum for the multi-step booking flow.
enum BookingStep {
  branch,
  service,
  employee,
  dateTime,
  customerInfo,
  confirmation,
}

/// Holds the in-progress booking selections.
class BookingSelections {
  final String? branchId;
  final String? branchName;
  final String? serviceId;
  final String? serviceName;
  final int? serviceDurationMins;
  final double? servicePrice;
  final String? employeeId;
  final String? employeeName;
  final DateTime? selectedDate;
  final DateTime? selectedSlot;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String notes;

  const BookingSelections({
    this.branchId,
    this.branchName,
    this.serviceId,
    this.serviceName,
    this.serviceDurationMins,
    this.servicePrice,
    this.employeeId,
    this.employeeName,
    this.selectedDate,
    this.selectedSlot,
    this.customerName = '',
    this.customerEmail = '',
    this.customerPhone = '',
    this.notes = '',
  });

  BookingSelections copyWith({
    String? branchId,
    String? branchName,
    String? serviceId,
    String? serviceName,
    int? serviceDurationMins,
    double? servicePrice,
    String? employeeId,
    String? employeeName,
    DateTime? selectedDate,
    DateTime? selectedSlot,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
  }) {
    return BookingSelections(
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceDurationMins: serviceDurationMins ?? this.serviceDurationMins,
      servicePrice: servicePrice ?? this.servicePrice,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
    );
  }
}

/// Holds employee info for the booking flow.
class BookableEmployee {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? title;

  const BookableEmployee({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.title,
  });
}

/// State provider for the complete public booking flow.
class PublicBookingProvider extends ChangeNotifier {
  final PublicBookingRepository _bookingRepo;
  final AvailabilityRepository _availabilityRepo;
  final SupabaseClient _client;

  PublicBookingProvider({
    required PublicBookingRepository bookingRepo,
    required AvailabilityRepository availabilityRepo,
    required SupabaseClient client,
  }) : _bookingRepo = bookingRepo,
       _availabilityRepo = availabilityRepo,
       _client = client;

  // ─── Flow state ────────────────────────────────────────────────────────────
  BookingStep _currentStep = BookingStep.branch;
  BookingSelections _selections = const BookingSelections();
  String? _businessSlug;

  // ─── Employees ─────────────────────────────────────────────────────────────
  List<BookableEmployee> _employees = [];
  bool _employeesLoading = false;
  String? _employeesError;

  // ─── Availability ──────────────────────────────────────────────────────────
  List<DateTime> _availableSlots = [];
  bool _slotsLoading = false;
  String? _slotsError;

  // ─── Booking result ────────────────────────────────────────────────────────
  PublicBookingResult? _bookingResult;
  bool _bookingLoading = false;
  String? _bookingError;

  // ─── Appointment lookup ────────────────────────────────────────────────────
  AppointmentTokenResult? _appointmentResult;
  bool _appointmentLoading = false;
  String? _appointmentError;
  bool _cancelLoading = false;
  String? _cancelError;
  bool _cancelSuccess = false;

  // ─── Getters ───────────────────────────────────────────────────────────────
  BookingStep get currentStep => _currentStep;
  BookingSelections get selections => _selections;
  String? get businessSlug => _businessSlug;

  List<BookableEmployee> get employees => List.unmodifiable(_employees);
  bool get employeesLoading => _employeesLoading;
  String? get employeesError => _employeesError;

  List<DateTime> get availableSlots => List.unmodifiable(_availableSlots);
  bool get slotsLoading => _slotsLoading;
  String? get slotsError => _slotsError;

  PublicBookingResult? get bookingResult => _bookingResult;
  bool get bookingLoading => _bookingLoading;
  String? get bookingError => _bookingError;

  AppointmentTokenResult? get appointmentResult => _appointmentResult;
  bool get appointmentLoading => _appointmentLoading;
  String? get appointmentError => _appointmentError;
  bool get cancelLoading => _cancelLoading;
  String? get cancelError => _cancelError;
  bool get cancelSuccess => _cancelSuccess;

  // ─── Flow control ──────────────────────────────────────────────────────────

  void initFlow(String businessSlug) {
    _businessSlug = businessSlug;
    _currentStep = BookingStep.branch;
    _selections = const BookingSelections();
    _availableSlots = [];
    _employees = [];
    _bookingResult = null;
    _bookingError = null;
    notifyListeners();
  }

  void goToStep(BookingStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void selectBranch(String branchId, String branchName) {
    _selections = _selections.copyWith(
      branchId: branchId,
      branchName: branchName,
    );
    _currentStep = BookingStep.service;
    notifyListeners();
  }

  void selectService({
    required String serviceId,
    required String serviceName,
    required int durationMins,
    required double price,
  }) {
    _selections = _selections.copyWith(
      serviceId: serviceId,
      serviceName: serviceName,
      serviceDurationMins: durationMins,
      servicePrice: price,
      // Reset downstream selections
      employeeId: null,
      employeeName: null,
      selectedDate: null,
      selectedSlot: null,
    );
    _currentStep = BookingStep.employee;
    _employees = [];
    notifyListeners();
    _loadEmployees();
  }

  void selectEmployee(String employeeId, String employeeName) {
    _selections = _selections.copyWith(
      employeeId: employeeId,
      employeeName: employeeName,
      selectedDate: null,
      selectedSlot: null,
    );
    _currentStep = BookingStep.dateTime;
    _availableSlots = [];
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selections = _selections.copyWith(selectedDate: date, selectedSlot: null);
    _availableSlots = [];
    notifyListeners();
    _loadSlots(date);
  }

  void selectSlot(DateTime slot) {
    _selections = _selections.copyWith(selectedSlot: slot);
    notifyListeners();
  }

  void proceedToCustomerInfo() {
    _currentStep = BookingStep.customerInfo;
    notifyListeners();
  }

  void updateCustomerInfo({
    String? name,
    String? email,
    String? phone,
    String? notes,
  }) {
    _selections = _selections.copyWith(
      customerName: name,
      customerEmail: email,
      customerPhone: phone,
      notes: notes,
    );
    notifyListeners();
  }

  // ─── Load employees for selected service/branch ────────────────────────────

  Future<void> _loadEmployees() async {
    if (_selections.branchId == null || _selections.serviceId == null) return;

    _employeesLoading = true;
    _employeesError = null;
    notifyListeners();

    try {
      final rows = await _client
          .from('employees')
          .select(
            'id, first_name, last_name, avatar_url, title, employee_services!inner(service_id)',
          )
          .eq('employee_services.service_id', _selections.serviceId!)
          .eq('status', 'active')
          .eq('is_bookable', true)
          .eq('is_active', true);

      _employees = (rows as List<dynamic>)
          .map(
            (r) => BookableEmployee(
              id: r['id'] as String,
              name: '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim(),
              avatarUrl: r['avatar_url'] as String?,
              title: r['title'] as String?,
            ),
          )
          .toList();
      _employeesError = null;
    } catch (e) {
      _employeesError = 'Could not load staff. Please try again.';
      AppLogger.error(
        'Load employees failed',
        tag: 'PublicBookingProvider',
        error: e,
      );
    }

    _employeesLoading = false;
    notifyListeners();
  }

  // ─── Load availability slots ───────────────────────────────────────────────

  Future<void> _loadSlots(DateTime date) async {
    if (_businessSlug == null ||
        _selections.branchId == null ||
        _selections.serviceId == null ||
        _selections.employeeId == null) {
      return;
    }

    _slotsLoading = true;
    _slotsError = null;
    notifyListeners();

    final result = await _availabilityRepo.getPublicAvailability(
      businessSlug: _businessSlug!,
      branchId: _selections.branchId!,
      serviceId: _selections.serviceId!,
      employeeId: _selections.employeeId!,
      date: date,
    );

    result.fold(
      onSuccess: (slots) {
        _availableSlots = slots.map((s) => s.startsAt).toList();
        _slotsError = _availableSlots.isEmpty
            ? 'No available times on this date.'
            : null;
      },
      onFailure: (f) {
        _slotsError = 'Could not load availability. Please try again.';
        _availableSlots = [];
      },
    );

    _slotsLoading = false;
    notifyListeners();
  }

  Future<void> reloadSlots() async {
    if (_selections.selectedDate != null) {
      await _loadSlots(_selections.selectedDate!);
    }
  }

  // ─── Submit booking ────────────────────────────────────────────────────────

  Future<bool> submitBooking() async {
    if (_businessSlug == null ||
        _selections.branchId == null ||
        _selections.serviceId == null ||
        _selections.employeeId == null ||
        _selections.selectedSlot == null) {
      _bookingError = 'Please complete all booking steps.';
      notifyListeners();
      return false;
    }

    _bookingLoading = true;
    _bookingError = null;
    notifyListeners();

    final result = await _bookingRepo.bookAppointment(
      businessSlug: _businessSlug!,
      branchId: _selections.branchId!,
      serviceId: _selections.serviceId!,
      employeeId: _selections.employeeId!,
      startTime: _selections.selectedSlot!,
      customerName: _selections.customerName,
      customerEmail: _selections.customerEmail,
      customerPhone: _selections.customerPhone.isEmpty
          ? null
          : _selections.customerPhone,
      notes: _selections.notes.isEmpty ? null : _selections.notes,
    );

    result.fold(
      onSuccess: (r) {
        _bookingResult = r;
        _bookingError = null;
        _currentStep = BookingStep.confirmation;
      },
      onFailure: (f) {
        _bookingError = f.message;
        _bookingResult = null;
      },
    );

    _bookingLoading = false;
    notifyListeners();
    return _bookingResult != null;
  }

  // ─── Appointment management ────────────────────────────────────────────────

  Future<void> loadAppointmentByToken(String token) async {
    _appointmentLoading = true;
    _appointmentError = null;
    _appointmentResult = null;
    _cancelSuccess = false;
    notifyListeners();

    final result = await _bookingRepo.getAppointmentByToken(token);

    result.fold(
      onSuccess: (r) {
        _appointmentResult = r;
        _appointmentError = null;
      },
      onFailure: (f) {
        _appointmentError = f is NotFoundFailure
            ? f.message
            : 'Could not load appointment. The link may be invalid or expired.';
      },
    );

    _appointmentLoading = false;
    notifyListeners();
  }

  Future<bool> cancelAppointment(String token, {String? reason}) async {
    _cancelLoading = true;
    _cancelError = null;
    notifyListeners();

    final result = await _bookingRepo.cancelAppointmentByToken(
      token,
      reason: reason,
    );

    result.fold(
      onSuccess: (_) {
        _cancelSuccess = true;
        _cancelError = null;
        // Refresh appointment data
        loadAppointmentByToken(token);
      },
      onFailure: (f) {
        _cancelError = f.message;
        _cancelSuccess = false;
      },
    );

    _cancelLoading = false;
    notifyListeners();
    return _cancelSuccess;
  }

  void resetBooking() {
    _currentStep = BookingStep.branch;
    _selections = const BookingSelections();
    _availableSlots = [];
    _employees = [];
    _bookingResult = null;
    _bookingError = null;
    notifyListeners();
  }
}
