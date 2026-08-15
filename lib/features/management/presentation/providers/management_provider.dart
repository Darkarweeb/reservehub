import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/management_entities.dart';

/// Central provider for the Business Management layer.
///
/// Manages: dashboard KPIs, customers CRM, branches, services,
/// employees, working hours, breaks, time off, business hours,
/// booking settings, schedule exceptions.
class ManagementProvider extends ChangeNotifier {
  final SupabaseClient _client;

  ManagementProvider({required SupabaseClient client}) : _client = client;

  // ─── State ─────────────────────────────────────────────────────────────────

  // Business context
  String? _businessId;
  String? _organizationId;

  // Dashboard
  DashboardKpiEntity? _kpis;
  bool _kpisLoading = false;
  String? _kpisError;

  // Customers
  List<CustomerCrmEntity> _customers = [];
  int _customersTotal = 0;
  bool _customersLoading = false;
  String? _customersError;

  // Branches
  List<ManagementBranchEntity> _branches = [];
  bool _branchesLoading = false;
  String? _branchesError;

  // Services
  List<ManagementServiceEntity> _services = [];
  bool _servicesLoading = false;
  String? _servicesError;

  // Employees
  List<ManagementEmployeeEntity> _employees = [];
  bool _employeesLoading = false;
  String? _employeesError;

  // Business hours
  List<BusinessHourEntity> _businessHours = [];
  bool _hoursLoading = false;
  String? _hoursError;

  // Booking settings
  BookingSettingsEntity? _bookingSettings;
  bool _settingsLoading = false;
  String? _settingsError;

  // Schedule exceptions
  List<ScheduleExceptionEntity> _scheduleExceptions = [];
  bool _exceptionsLoading = false;

  // Employee working hours (keyed by employee id)
  final Map<String, List<EmployeeWorkingHourEntity>> _employeeHours = {};
  final Map<String, List<EmployeeBreakEntity>> _employeeBreaks = {};
  final Map<String, List<EmployeeTimeOffEntity>> _employeeTimeOff = {};

  // Save state
  bool _isSaving = false;
  String? _saveError;
  String? _saveSuccess;

  // ─── Getters ───────────────────────────────────────────────────────────────

  String? get businessId => _businessId;
  String? get organizationId => _organizationId;

  DashboardKpiEntity? get kpis => _kpis;
  bool get kpisLoading => _kpisLoading;
  String? get kpisError => _kpisError;

  List<CustomerCrmEntity> get customers => List.unmodifiable(_customers);
  int get customersTotal => _customersTotal;
  bool get customersLoading => _customersLoading;
  String? get customersError => _customersError;

  List<ManagementBranchEntity> get branches => List.unmodifiable(_branches);
  bool get branchesLoading => _branchesLoading;
  String? get branchesError => _branchesError;

  List<ManagementServiceEntity> get services => List.unmodifiable(_services);
  bool get servicesLoading => _servicesLoading;
  String? get servicesError => _servicesError;

  List<ManagementEmployeeEntity> get employees => List.unmodifiable(_employees);
  bool get employeesLoading => _employeesLoading;
  String? get employeesError => _employeesError;

  List<BusinessHourEntity> get businessHours =>
      List.unmodifiable(_businessHours);
  bool get hoursLoading => _hoursLoading;
  String? get hoursError => _hoursError;

  BookingSettingsEntity? get bookingSettings => _bookingSettings;
  bool get settingsLoading => _settingsLoading;
  String? get settingsError => _settingsError;

  List<ScheduleExceptionEntity> get scheduleExceptions =>
      List.unmodifiable(_scheduleExceptions);
  bool get exceptionsLoading => _exceptionsLoading;

  bool get isSaving => _isSaving;
  String? get saveError => _saveError;
  String? get saveSuccess => _saveSuccess;

  List<EmployeeWorkingHourEntity> employeeHours(String employeeId) =>
      List.unmodifiable(_employeeHours[employeeId] ?? []);
  List<EmployeeBreakEntity> employeeBreaks(String employeeId) =>
      List.unmodifiable(_employeeBreaks[employeeId] ?? []);
  List<EmployeeTimeOffEntity> employeeTimeOff(String employeeId) =>
      List.unmodifiable(_employeeTimeOff[employeeId] ?? []);

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Initialize with business context. Call after onboarding is complete.
  Future<void> initialize() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Get org
      final orgMember = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (orgMember == null) return;
      _organizationId = orgMember['organization_id'] as String;

      // Get business
      final business = await _client
          .from('businesses')
          .select('id')
          .eq('organization_id', _organizationId!)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (business == null) return;
      _businessId = business['id'] as String;

      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'ManagementProvider.initialize failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }
  }

  // ─── Dashboard KPIs ────────────────────────────────────────────────────────

  Future<void> loadDashboardKpis() async {
    _kpisLoading = true;
    _kpisError = null;
    notifyListeners();

    try {
      final response = await _client.rpc('get_dashboard_kpis');
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        _kpis = DashboardKpiEntity(
          todayCount: (data['today_count'] as num?)?.toInt() ?? 0,
          yesterdayCount: (data['yesterday_count'] as num?)?.toInt() ?? 0,
          upcomingCount: (data['upcoming_count'] as num?)?.toInt() ?? 0,
          completedCount: (data['completed_count'] as num?)?.toInt() ?? 0,
          cancelledCount: (data['cancelled_count'] as num?)?.toInt() ?? 0,
          customerCount: (data['customer_count'] as num?)?.toInt() ?? 0,
          appointmentValue:
              (data['appointment_value'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.now(),
        );
      } else {
        _kpisError = data['message'] as String? ?? 'Failed to load KPIs';
      }
    } catch (e) {
      _kpisError = 'Failed to load dashboard data';
      AppLogger.error(
        'loadDashboardKpis failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }

    _kpisLoading = false;
    notifyListeners();
  }

  // ─── Customers ─────────────────────────────────────────────────────────────

  Future<void> loadCustomers({String? search, String? status}) async {
    _customersLoading = true;
    _customersError = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'get_customers_list',
        params: {
          'p_search': search,
          'p_status': status,
          'p_limit': 100,
          'p_offset': 0,
        },
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final list = (data['customers'] as List<dynamic>? ?? []);
        _customers = list
            .map((e) => CustomerCrmEntity.fromJson(e as Map<String, dynamic>))
            .toList();
        _customersTotal = (data['total'] as num?)?.toInt() ?? _customers.length;
      } else {
        _customersError =
            data['message'] as String? ?? 'Failed to load customers';
      }
    } catch (e) {
      _customersError = 'Failed to load customers';
      AppLogger.error('loadCustomers failed', tag: 'MgmtProvider', error: e);
    }

    _customersLoading = false;
    notifyListeners();
  }

  // ─── Branches ──────────────────────────────────────────────────────────────

  Future<void> loadBranches() async {
    if (_businessId == null) return;
    _branchesLoading = true;
    _branchesError = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'get_branches_for_management',
        params: {'p_business_id': _businessId},
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final list = (data['branches'] as List<dynamic>? ?? []);
        _branches = list
            .map(
              (e) => ManagementBranchEntity.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } else {
        _branchesError = data['message'] as String?;
      }
    } catch (e) {
      _branchesError = 'Failed to load branches';
      AppLogger.error('loadBranches failed', tag: 'MgmtProvider', error: e);
    }

    _branchesLoading = false;
    notifyListeners();
  }

  Future<Result<void>> saveBranch({
    String? branchId,
    required String name,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? timezone,
  }) async {
    _setSaving(true);
    try {
      if (branchId != null) {
        await _client
            .from('branches')
            .update({
              'name': name,
              'address': address,
              'city': city,
              'country': country,
              'phone': phone,
              'email': email,
              'timezone': timezone,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', branchId);
      } else {
        await _client.from('branches').insert({
          'organization_id': _organizationId,
          'business_id': _businessId,
          'name': name,
          'address': address,
          'city': city,
          'country': country,
          'phone': phone,
          'email': email,
          'timezone': timezone ?? 'UTC',
        });
      }
      await loadBranches();
      _setSaving(false, success: 'Branch saved successfully');
      return success(null);
    } catch (e) {
      _setSaving(false, error: 'Failed to save branch');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> toggleBranchActive(
    String branchId,
    bool isActive,
  ) async {
    try {
      await _client
          .from('branches')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', branchId);
      await loadBranches();
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Services ──────────────────────────────────────────────────────────────

  Future<void> loadServices() async {
    if (_businessId == null) return;
    _servicesLoading = true;
    _servicesError = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'get_services_for_management',
        params: {'p_business_id': _businessId},
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final list = (data['services'] as List<dynamic>? ?? []);
        _services = list
            .map(
              (e) =>
                  ManagementServiceEntity.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } else {
        _servicesError = data['message'] as String?;
      }
    } catch (e) {
      _servicesError = 'Failed to load services';
      AppLogger.error('loadServices failed', tag: 'MgmtProvider', error: e);
    }

    _servicesLoading = false;
    notifyListeners();
  }

  Future<Result<void>> saveService({
    String? serviceId,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
    int bufferBefore = 0,
    int bufferAfter = 0,
    bool isActive = true,
    String? colorHex,
    String? category,
  }) async {
    _setSaving(true);
    try {
      final payload = {
        'organization_id': _organizationId,
        'name': name,
        'description': description,
        'duration_minutes': durationMinutes,
        'price': price,
        'buffer_before_minutes': bufferBefore,
        'buffer_after_minutes': bufferAfter,
        'is_active': isActive,
        'color_hex': colorHex,
        'category': category,
      };

      if (serviceId != null) {
        await _client
            .from('services')
            .update({
              ...payload,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', serviceId);
      } else {
        await _client.from('services').insert(payload);
      }
      await loadServices();
      _setSaving(false, success: 'Service saved successfully');
      return success(null);
    } catch (e) {
      _setSaving(false, error: 'Failed to save service');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> toggleServiceActive(
    String serviceId,
    bool isActive,
  ) async {
    try {
      await _client
          .from('services')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', serviceId);
      await loadServices();
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Employees ─────────────────────────────────────────────────────────────

  Future<void> loadEmployees() async {
    if (_businessId == null) return;
    _employeesLoading = true;
    _employeesError = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'get_employees_for_management',
        params: {'p_business_id': _businessId},
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final list = (data['employees'] as List<dynamic>? ?? []);
        _employees = list
            .map(
              (e) =>
                  ManagementEmployeeEntity.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } else {
        _employeesError = data['message'] as String?;
      }
    } catch (e) {
      _employeesError = 'Failed to load employees';
      AppLogger.error('loadEmployees failed', tag: 'MgmtProvider', error: e);
    }

    _employeesLoading = false;
    notifyListeners();
  }

  Future<Result<void>> saveEmployee({
    String? employeeId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? title,
    bool isBookable = true,
    String status = 'active',
  }) async {
    _setSaving(true);
    try {
      final payload = {
        'organization_id': _organizationId,
        'business_id': _businessId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'title': title,
        'is_bookable': isBookable,
        'status': status,
      };

      if (employeeId != null) {
        await _client
            .from('employees')
            .update({
              ...payload,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', employeeId);
      } else {
        await _client.from('employees').insert(payload);
      }
      await loadEmployees();
      _setSaving(false, success: 'Employee saved successfully');
      return success(null);
    } catch (e) {
      _setSaving(false, error: 'Failed to save employee');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> toggleEmployeeStatus(
    String employeeId,
    String status,
  ) async {
    try {
      await _client
          .from('employees')
          .update({
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', employeeId);
      await loadEmployees();
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Employee Working Hours ─────────────────────────────────────────────────

  Future<void> loadEmployeeWorkingHours(String employeeId) async {
    try {
      final response = await _client.rpc(
        'get_employee_working_hours',
        params: {'p_employee_id': employeeId},
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final list = (data['hours'] as List<dynamic>? ?? []);
        _employeeHours[employeeId] = list
            .map(
              (e) =>
                  EmployeeWorkingHourEntity.fromJson(e as Map<String, dynamic>),
            )
            .toList();

        // Fill missing days with defaults
        const days = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ];
        final existing = _employeeHours[employeeId]!
            .map((h) => h.dayOfWeek)
            .toSet();
        for (final day in days) {
          if (!existing.contains(day)) {
            _employeeHours[employeeId]!.add(
              EmployeeWorkingHourEntity(
                dayOfWeek: day,
                isWorking: day != 'saturday' && day != 'sunday',
                startTime: '09:00',
                endTime: '17:00',
              ),
            );
          }
        }
        _employeeHours[employeeId]!.sort((a, b) {
          const order = [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday',
          ];
          return order
              .indexOf(a.dayOfWeek)
              .compareTo(order.indexOf(b.dayOfWeek));
        });
      }
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'loadEmployeeWorkingHours failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }
  }

  Future<Result<void>> saveEmployeeWorkingHours(
    String employeeId,
    List<EmployeeWorkingHourEntity> hours,
  ) async {
    _setSaving(true);
    try {
      final hoursJson = hours.map((h) => h.toJson()).toList();
      final response = await _client.rpc(
        'upsert_employee_working_hours',
        params: {'p_employee_id': employeeId, 'p_hours': hoursJson},
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        _employeeHours[employeeId] = hours;
        _setSaving(false, success: 'Working hours saved');
        return success(null);
      }
      _setSaving(false, error: data['message'] as String? ?? 'Failed to save');
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      _setSaving(false, error: 'Failed to save working hours');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  void updateLocalEmployeeHour(
    String employeeId,
    int index,
    EmployeeWorkingHourEntity updated,
  ) {
    final list = List<EmployeeWorkingHourEntity>.from(
      _employeeHours[employeeId] ?? [],
    );
    if (index < list.length) {
      list[index] = updated;
      _employeeHours[employeeId] = list;
      notifyListeners();
    }
  }

  // ─── Employee Breaks ───────────────────────────────────────────────────────

  Future<void> loadEmployeeBreaks(String employeeId) async {
    try {
      final response = await _client
          .from('employee_breaks')
          .select()
          .eq('employee_id', employeeId)
          .eq('is_active', true)
          .order('start_time');

      _employeeBreaks[employeeId] = (response as List<dynamic>)
          .map((e) => EmployeeBreakEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'loadEmployeeBreaks failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }
  }

  Future<Result<void>> addEmployeeBreak({
    required String employeeId,
    required String breakName,
    String? dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _client.rpc(
        'manage_employee_break',
        params: {
          'p_action': 'create',
          'p_employee_id': employeeId,
          'p_break_name': breakName,
          'p_day_of_week': dayOfWeek,
          'p_start_time': startTime,
          'p_end_time': endTime,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await loadEmployeeBreaks(employeeId);
        return success(null);
      }
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteEmployeeBreak(
    String employeeId,
    String breakId,
  ) async {
    try {
      final response = await _client.rpc(
        'manage_employee_break',
        params: {'p_action': 'delete', 'p_break_id': breakId},
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await loadEmployeeBreaks(employeeId);
        return success(null);
      }
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Employee Time Off ─────────────────────────────────────────────────────

  Future<void> loadEmployeeTimeOff(String employeeId) async {
    try {
      final response = await _client
          .from('employee_time_off')
          .select()
          .eq('employee_id', employeeId)
          .gte('end_datetime', DateTime.now().toUtc().toIso8601String())
          .order('start_datetime');

      _employeeTimeOff[employeeId] = (response as List<dynamic>)
          .map((e) => EmployeeTimeOffEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'loadEmployeeTimeOff failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }
  }

  Future<Result<void>> addEmployeeTimeOff({
    required String employeeId,
    required DateTime startDatetime,
    required DateTime endDatetime,
    String? reason,
    String timeOffType = 'unavailable',
  }) async {
    try {
      final response = await _client.rpc(
        'manage_employee_time_off',
        params: {
          'p_action': 'create',
          'p_employee_id': employeeId,
          'p_start_datetime': startDatetime.toUtc().toIso8601String(),
          'p_end_datetime': endDatetime.toUtc().toIso8601String(),
          'p_reason': reason,
          'p_time_off_type': timeOffType,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await loadEmployeeTimeOff(employeeId);
        return success(null);
      }
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteEmployeeTimeOff(
    String employeeId,
    String timeOffId,
  ) async {
    try {
      final response = await _client.rpc(
        'manage_employee_time_off',
        params: {'p_action': 'delete', 'p_time_off_id': timeOffId},
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await loadEmployeeTimeOff(employeeId);
        return success(null);
      }
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Business Hours ────────────────────────────────────────────────────────

  Future<void> loadBusinessHours({String? branchId}) async {
    if (_businessId == null) return;
    _hoursLoading = true;
    _hoursError = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'get_business_hours_for_management',
        params: {'p_business_id': _businessId, 'p_branch_id': branchId},
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final list = (data['hours'] as List<dynamic>? ?? []);
        _businessHours = list
            .map((e) => BusinessHourEntity.fromJson(e as Map<String, dynamic>))
            .toList();

        // Fill missing days
        const days = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ];
        final existing = _businessHours.map((h) => h.dayOfWeek).toSet();
        for (final day in days) {
          if (!existing.contains(day)) {
            _businessHours.add(
              BusinessHourEntity(
                dayOfWeek: day,
                isOpen: day != 'saturday' && day != 'sunday',
                openTime: '09:00',
                closeTime: '18:00',
              ),
            );
          }
        }
        _businessHours.sort((a, b) {
          const order = [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday',
          ];
          return order
              .indexOf(a.dayOfWeek)
              .compareTo(order.indexOf(b.dayOfWeek));
        });
      } else {
        _hoursError = data['message'] as String?;
      }
    } catch (e) {
      _hoursError = 'Failed to load business hours';
      AppLogger.error(
        'loadBusinessHours failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }

    _hoursLoading = false;
    notifyListeners();
  }

  Future<Result<void>> saveBusinessHours(
    List<BusinessHourEntity> hours, {
    String? branchId,
  }) async {
    if (_businessId == null) {
      return failure(const ServerFailure(message: 'No business'));
    }
    _setSaving(true);
    try {
      final hoursJson = hours.map((h) => h.toJson()).toList();
      final response = await _client.rpc(
        'upsert_business_hours',
        params: {
          'p_business_id': _businessId,
          'p_hours': hoursJson,
          'p_branch_id': branchId,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        _businessHours = hours;
        _setSaving(false, success: 'Business hours saved');
        return success(null);
      }
      _setSaving(false, error: data['message'] as String? ?? 'Failed');
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      _setSaving(false, error: 'Failed to save business hours');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  void updateLocalBusinessHour(int index, BusinessHourEntity updated) {
    final list = List<BusinessHourEntity>.from(_businessHours);
    if (index < list.length) {
      list[index] = updated;
      _businessHours = list;
      notifyListeners();
    }
  }

  // ─── Booking Settings ──────────────────────────────────────────────────────

  Future<void> loadBookingSettings() async {
    if (_businessId == null) return;
    _settingsLoading = true;
    _settingsError = null;
    notifyListeners();

    try {
      final response = await _client.rpc(
        'get_booking_settings_for_management',
        params: {'p_business_id': _businessId},
      );
      final data = response as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final settings = data['settings'] as Map<String, dynamic>? ?? {};
        final policy = data['cancellation_policy'] as Map<String, dynamic>?;
        _bookingSettings = BookingSettingsEntity.fromJson(settings, policy);
      } else {
        _settingsError = data['message'] as String?;
      }
    } catch (e) {
      _settingsError = 'Failed to load booking settings';
      AppLogger.error(
        'loadBookingSettings failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }

    _settingsLoading = false;
    notifyListeners();
  }

  Future<Result<void>> saveBookingSettings(
    BookingSettingsEntity settings,
  ) async {
    if (_businessId == null) {
      return failure(const ServerFailure(message: 'No business'));
    }
    _setSaving(true);
    try {
      final response = await _client.rpc(
        'upsert_booking_settings',
        params: {
          'p_business_id': _businessId,
          'p_online_booking_enabled': settings.onlineBookingEnabled,
          'p_guest_booking_enabled': settings.guestBookingEnabled,
          'p_auto_confirm': settings.autoConfirm,
          'p_min_booking_notice_hours': settings.minBookingNoticeHours,
          'p_max_booking_horizon_days': settings.maxBookingHorizonDays,
          'p_slot_duration_minutes': settings.slotDurationMinutes,
          'p_allow_rescheduling': settings.allowRescheduling,
          'p_reschedule_notice_hours': settings.rescheduleNoticeHours,
          'p_max_reschedules': settings.maxReschedules,
          'p_cancellation_allowed': settings.cancellationAllowed,
          'p_cancellation_notice_hours': settings.cancellationNoticeHours,
          'p_cancellation_fee': settings.cancellationFee,
          'p_no_show_fee': settings.noShowFee,
          'p_policy_text': settings.policyText,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        _bookingSettings = settings;
        _setSaving(false, success: 'Booking settings saved');
        return success(null);
      }
      _setSaving(false, error: data['message'] as String? ?? 'Failed');
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      _setSaving(false, error: 'Failed to save booking settings');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Schedule Exceptions ───────────────────────────────────────────────────

  Future<void> loadScheduleExceptions() async {
    if (_businessId == null) return;
    _exceptionsLoading = true;
    notifyListeners();

    try {
      final response = await _client
          .from('schedule_exceptions')
          .select()
          .eq('business_id', _businessId!)
          .gte(
            'exception_date',
            DateTime.now().toIso8601String().substring(0, 10),
          )
          .order('exception_date');

      _scheduleExceptions = (response as List<dynamic>)
          .map(
            (e) => ScheduleExceptionEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      AppLogger.error(
        'loadScheduleExceptions failed',
        tag: 'MgmtProvider',
        error: e,
      );
    }

    _exceptionsLoading = false;
    notifyListeners();
  }

  Future<Result<void>> addScheduleException({
    required DateTime date,
    required bool isClosed,
    String? openTime,
    String? closeTime,
    String? reason,
    String exceptionType = 'modified_hours',
    String? branchId,
  }) async {
    if (_businessId == null) {
      return failure(const ServerFailure(message: 'No business'));
    }
    try {
      final response = await _client.rpc(
        'manage_schedule_exception',
        params: {
          'p_action': 'create',
          'p_business_id': _businessId,
          'p_exception_date': date.toIso8601String().substring(0, 10),
          'p_is_closed': isClosed,
          'p_open_time': openTime,
          'p_close_time': closeTime,
          'p_reason': reason,
          'p_exception_type': exceptionType,
          'p_branch_id': branchId,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await loadScheduleExceptions();
        return success(null);
      }
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteScheduleException(String exceptionId) async {
    try {
      final response = await _client.rpc(
        'manage_schedule_exception',
        params: {
          'p_action': 'delete',
          'p_business_id': _businessId,
          'p_exception_date': DateTime.now().toIso8601String().substring(0, 10),
          'p_exception_id': exceptionId,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await loadScheduleExceptions();
        return success(null);
      }
      return failure(
        ServerFailure(message: data['message'] as String? ?? 'Failed'),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Business Profile ──────────────────────────────────────────────────────

  Future<Result<void>> updateBusinessProfile({
    required String name,
    String? description,
    String? email,
    String? phone,
    String? website,
    String? timezone,
    String? address,
    String? city,
    String? country,
  }) async {
    if (_businessId == null) {
      return failure(const ServerFailure(message: 'No business'));
    }
    _setSaving(true);
    try {
      await _client
          .from('businesses')
          .update({
            'name': name,
            'description': description,
            'email': email,
            'phone': phone,
            'website': website,
            'timezone': timezone,
            'address': address,
            'city': city,
            'country': country,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _businessId!);
      _setSaving(false, success: 'Business profile updated');
      return success(null);
    } catch (e) {
      _setSaving(false, error: 'Failed to update business profile');
      return failure(ServerFailure(message: e.toString()));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setSaving(bool saving, {String? error, String? success}) {
    _isSaving = saving;
    _saveError = error;
    _saveSuccess = success;
    notifyListeners();
  }

  void clearSaveState() {
    _saveError = null;
    _saveSuccess = null;
    notifyListeners();
  }

}
