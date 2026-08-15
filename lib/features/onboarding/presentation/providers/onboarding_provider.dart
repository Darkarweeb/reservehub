import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../business/domain/entities/business_entity.dart';
import '../../../business/domain/repositories/business_repository.dart';
import '../../../business/data/models/business_model.dart';
import '../../../business_settings/domain/entities/organization_entity.dart';
import '../../../business_settings/domain/repositories/organization_repository.dart';
import '../../domain/entities/onboarding_entities.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';

/// Provider managing the complete business onboarding flow.
///
/// Responsibilities:
/// - Persist each step to Supabase immediately (idempotent upserts)
/// - Resume interrupted onboarding without creating duplicates
/// - Expose loading/error state to the UI
/// - Keep all business logic outside widgets
class OnboardingProvider extends ChangeNotifier {
  final OrganizationRepository _orgRepository;
  final BusinessRepository _businessRepository;
  final SupabaseClient _client;

  OnboardingProgressEntity _progress = const OnboardingProgressEntity();
  bool _isLoading = false;
  String? _errorMessage;

  // ─── In-memory draft state ─────────────────────────────────────────────────
  OrganizationEntity? _organization;
  BusinessEntity? _business;
  BranchEntity? _branch;
  List<OnboardingServiceEntity> _services = [];
  List<OnboardingEmployeeEntity> _employees = [];
  List<OnboardingDayHours> _businessHours = _defaultBusinessHours();
  OnboardingBookingSettings _bookingSettings =
      const OnboardingBookingSettings();

  OnboardingProvider({
    required OrganizationRepository orgRepository,
    required BusinessRepository businessRepository,
    required SupabaseClient client,
  }) : _orgRepository = orgRepository,
       _businessRepository = businessRepository,
       _client = client;

  // ─── Getters ───────────────────────────────────────────────────────────────

  OnboardingProgressEntity get progress => _progress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OnboardingStep get currentStep => _progress.currentStep;
  double get progressPercent => _progress.progressPercent;

  OrganizationEntity? get organization => _organization;
  BusinessEntity? get business => _business;
  BranchEntity? get branch => _branch;
  List<OnboardingServiceEntity> get services => List.unmodifiable(_services);
  List<OnboardingEmployeeEntity> get employees => List.unmodifiable(_employees);
  List<OnboardingDayHours> get businessHours =>
      List.unmodifiable(_businessHours);
  OnboardingBookingSettings get bookingSettings => _bookingSettings;

  bool get hasOrganization => _progress.organizationId != null;
  bool get hasBusiness => _progress.businessId != null;
  bool get hasBranch => _progress.branchId != null;

  // ─── Initialization / Resume ───────────────────────────────────────────────

  /// Called on app start for authenticated users.
  /// Loads existing onboarding state from Supabase (resume support).
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // 1. Load organization
      final orgResult = await _orgRepository.getCurrentOrganization();
      orgResult.fold(
        onSuccess: (org) {
          if (org != null) {
            _organization = org;
            _progress = _progress.copyWith(organizationId: org.id);
            _markCompleted(OnboardingStep.organization);
          }
        },
        onFailure: (_) {},
      );

      if (_progress.organizationId == null) {
        _setLoading(false);
        return;
      }

      // 2. Load business
      final bizResult = await _businessRepository.getBusinesses(
        _progress.organizationId!,
      );
      bizResult.fold(
        onSuccess: (businesses) {
          if (businesses.isNotEmpty) {
            _business = businesses.first;
            _progress = _progress.copyWith(businessId: _business!.id);
            _markCompleted(OnboardingStep.business);
          }
        },
        onFailure: (_) {},
      );

      if (_progress.businessId == null) {
        _setLoading(false);
        return;
      }

      // 3. Load branch
      final branchResult = await _businessRepository.getBranches(
        _progress.businessId!,
      );
      branchResult.fold(
        onSuccess: (branches) {
          if (branches.isNotEmpty) {
            _branch = branches.first;
            _progress = _progress.copyWith(branchId: _branch!.id);
            _markCompleted(OnboardingStep.branch);
          }
        },
        onFailure: (_) {},
      );

      // 4. Load services
      await _loadServices();

      // 5. Load employees
      await _loadEmployees();

      // 6. Load business hours
      await _loadBusinessHours();

      // 7. Load booking settings
      await _loadBookingSettings();

      // Determine current step (first incomplete step)
      _progress = _progress.copyWith(currentStep: _firstIncompleteStep());
    } catch (e, st) {
      AppLogger.error(
        'OnboardingProvider.initialize failed',
        tag: 'OnboardingProvider',
        error: e,
        stackTrace: st,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ─── Step 1: Organization ──────────────────────────────────────────────────

  Future<bool> saveOrganization({
    required String name,
    String? ownerName,
    String? email,
    String? phone,
    String? timezone,
    String? currency,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      if (_organization != null) {
        // Update existing
        final updated = _organization!.copyWith(
          name: name,
          email: email,
          phone: phone,
          timezone: timezone,
          currency: currency,
        );
        final result = await _orgRepository.updateOrganization(updated);
        return result.fold(
          onSuccess: (org) {
            _organization = org;
            _progress = _progress.copyWith(organizationId: org.id);
            _markCompleted(OnboardingStep.organization);
            return true;
          },
          onFailure: (f) {
            _setError(f.message);
            return false;
          },
        );
      } else {
        // Create new
        final result = await _orgRepository.createOrganization(
          name: name,
          email: email,
          phone: phone,
          timezone: timezone ?? 'UTC',
          currency: currency ?? 'USD',
        );
        return result.fold(
          onSuccess: (org) {
            _organization = org;
            _progress = _progress.copyWith(organizationId: org.id);
            _markCompleted(OnboardingStep.organization);
            return true;
          },
          onFailure: (f) {
            _setError(f.message);
            return false;
          },
        );
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Step 2: Business ──────────────────────────────────────────────────────

  Future<bool> saveBusiness({
    required String name,
    String? slug,
    String? description,
    String? categoryId,
    String? phone,
    String? email,
    String? website,
    String? timezone,
    String? currency,
  }) async {
    if (_progress.organizationId == null) {
      _setError('Organization must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      if (_business != null) {
        // Update existing
        final updated = _business!.copyWith(
          name: name,
          slug: slug,
          description: description,
          categoryId: categoryId,
          phone: phone,
          email: email,
          website: website,
          timezone: timezone,
        );
        final result = await _businessRepository.updateBusiness(updated);
        return result.fold(
          onSuccess: (biz) {
            _business = biz;
            _progress = _progress.copyWith(businessId: biz.id);
            _markCompleted(OnboardingStep.business);
            return true;
          },
          onFailure: (f) {
            _setError(f.message);
            return false;
          },
        );
      } else {
        // Create new
        final newBusiness = BusinessModel(
          id: '',
          organizationId: _progress.organizationId!,
          name: name,
          slug: slug,
          description: description,
          categoryId: categoryId,
          phone: phone,
          email: email,
          website: website,
          timezone: timezone ?? 'UTC',
          createdAt: DateTime.now(),
        );
        final result = await _businessRepository.createBusiness(newBusiness);
        return result.fold(
          onSuccess: (biz) {
            _business = biz;
            _progress = _progress.copyWith(businessId: biz.id);
            _markCompleted(OnboardingStep.business);
            return true;
          },
          onFailure: (f) {
            _setError(f.message);
            return false;
          },
        );
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Checks if a slug is available (not taken by another business).
  Future<bool> isSlugAvailable(String slug) async {
    try {
      final result = await _businessRepository.getBusinessBySlug(slug);
      return result.fold(
        onSuccess: (biz) => biz.id == (_business?.id ?? ''),
        onFailure: (f) => f is NotFoundFailure,
      );
    } catch (_) {
      return false;
    }
  }

  // ─── Step 3: Branch ────────────────────────────────────────────────────────

  Future<bool> saveBranch({
    required String name,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? timezone,
  }) async {
    if (_progress.businessId == null) {
      _setError('Business must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      if (_branch != null) {
        // Update existing branch
        final updated = BranchEntity(
          id: _branch!.id,
          organizationId: _branch!.organizationId,
          businessId: _branch!.businessId,
          name: name,
          address: address,
          city: city,
          country: country,
          phone: phone,
          email: email,
          timezone: timezone,
          isActive: true,
          createdAt: _branch!.createdAt,
        );
        final result = await _businessRepository.updateBranch(updated);
        return result.fold(
          onSuccess: (br) {
            _branch = br;
            _progress = _progress.copyWith(branchId: br.id);
            _markCompleted(OnboardingStep.branch);
            return true;
          },
          onFailure: (f) {
            _setError(f.message);
            return false;
          },
        );
      } else {
        // Create new branch
        final newBranch = BranchEntity(
          id: '',
          organizationId: _progress.organizationId!,
          businessId: _progress.businessId!,
          name: name,
          address: address,
          city: city,
          country: country,
          phone: phone,
          email: email,
          timezone: timezone,
          isActive: true,
          createdAt: DateTime.now(),
        );
        final result = await _businessRepository.createBranch(newBranch);
        return result.fold(
          onSuccess: (br) {
            _branch = br;
            _progress = _progress.copyWith(branchId: br.id);
            _markCompleted(OnboardingStep.branch);
            return true;
          },
          onFailure: (f) {
            _setError(f.message);
            return false;
          },
        );
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Step 4: Services ──────────────────────────────────────────────────────

  Future<bool> saveService(OnboardingServiceEntity service) async {
    if (_progress.businessId == null) {
      _setError('Business must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      final orgId = _progress.organizationId!;
      final bizId = _progress.businessId!;

      if (service.id != null) {
        // Update existing
        await _client
            .from('services')
            .update({
              'name': service.name,
              'description': service.description,
              'duration_mins': service.durationMins,
              'buffer_before_mins': service.bufferBeforeMins,
              'buffer_after_mins': service.bufferAfterMins,
              'price': service.price,
              'currency': service.currency,
              'status': service.isActive ? 'active' : 'inactive',
            })
            .eq('id', service.id!);

        final idx = _services.indexWhere((s) => s.id == service.id);
        if (idx >= 0) _services[idx] = service;
      } else {
        // Create new
        final slug = _slugify(service.name);
        final response = await _client
            .from('services')
            .insert({
              'organization_id': orgId,
              'business_id': bizId,
              'name': service.name,
              'slug': slug,
              'description': service.description,
              'duration_mins': service.durationMins,
              'buffer_before_mins': service.bufferBeforeMins,
              'buffer_after_mins': service.bufferAfterMins,
              'price': service.price,
              'currency': service.currency,
              'status': service.isActive ? 'active' : 'inactive',
            })
            .select()
            .single();

        final created = service.copyWith(id: response['id'] as String);
        _services.add(created);

        // Link to branch if available
        if (_progress.branchId != null) {
          await _client.from('branch_services').upsert({
            'organization_id': orgId,
            'branch_id': _progress.branchId!,
            'service_id': created.id!,
          }, onConflict: 'branch_id,service_id');
        }
      }

      if (_services.isNotEmpty) {
        _markCompleted(OnboardingStep.services);
      }
      return true;
    } on PostgrestException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    _clearError();
    try {
      await _client
          .from('services')
          .update({
            'status': 'inactive',
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', serviceId);
      _services.removeWhere((s) => s.id == serviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void markServicesComplete() {
    _markCompleted(OnboardingStep.services);
  }

  // ─── Step 5: Employees ─────────────────────────────────────────────────────

  Future<bool> saveEmployee(OnboardingEmployeeEntity employee) async {
    if (_progress.businessId == null) {
      _setError('Business must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      final orgId = _progress.organizationId!;
      final bizId = _progress.businessId!;

      String employeeId;

      if (employee.id != null) {
        // Update existing
        await _client
            .from('employees')
            .update({
              'first_name': employee.firstName,
              'last_name': employee.lastName,
              'email': employee.email,
              'phone': employee.phone,
              'avatar_url': employee.avatarUrl,
              'status': employee.isActive ? 'active' : 'inactive',
              'is_bookable': employee.isBookable,
            })
            .eq('id', employee.id!);
        employeeId = employee.id!;

        final idx = _employees.indexWhere((e) => e.id == employee.id);
        if (idx >= 0) _employees[idx] = employee;
      } else {
        // Create new
        final response = await _client
            .from('employees')
            .insert({
              'organization_id': orgId,
              'business_id': bizId,
              'branch_id': _progress.branchId,
              'first_name': employee.firstName,
              'last_name': employee.lastName,
              'email': employee.email,
              'phone': employee.phone,
              'avatar_url': employee.avatarUrl,
              'status': employee.isActive ? 'active' : 'inactive',
              'is_bookable': employee.isBookable,
            })
            .select()
            .single();

        employeeId = response['id'] as String;
        final created = employee.copyWith(id: employeeId);
        _employees.add(created);
      }

      // Sync service assignments
      await _syncEmployeeServices(employeeId, employee.serviceIds, orgId);

      if (_employees.isNotEmpty) {
        _markCompleted(OnboardingStep.employees);
      }
      return true;
    } on PostgrestException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncEmployeeServices(
    String employeeId,
    List<String> serviceIds,
    String orgId,
  ) async {
    // Delete existing assignments
    await _client
        .from('employee_services')
        .delete()
        .eq('employee_id', employeeId);

    // Insert new assignments
    if (serviceIds.isNotEmpty) {
      final rows = serviceIds
          .map(
            (sid) => {
              'organization_id': orgId,
              'employee_id': employeeId,
              'service_id': sid,
            },
          )
          .toList();
      await _client.from('employee_services').insert(rows);
    }
  }

  void markEmployeesComplete() {
    _markCompleted(OnboardingStep.employees);
  }

  // ─── Step 6: Business Hours ────────────────────────────────────────────────

  void updateDayHours(OnboardingDayHours day) {
    final idx = _businessHours.indexWhere((d) => d.dayOfWeek == day.dayOfWeek);
    if (idx >= 0) {
      _businessHours[idx] = day;
    }
    notifyListeners();
  }

  Future<bool> saveBusinessHours() async {
    if (_progress.businessId == null) {
      _setError('Business must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      final orgId = _progress.organizationId!;
      final bizId = _progress.businessId!;

      // Map day_of_week int to PostgreSQL enum
      const dayNames = [
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ];

      for (final day in _businessHours) {
        final dayEnum = dayNames[day.dayOfWeek];
        await _client.from('business_hours').upsert(
          {
            'organization_id': orgId,
            'business_id': bizId,
            'branch_id': _progress.branchId,
            'day_of_week': dayEnum,
            'is_open': day.isOpen,
            'open_time': day.isOpen ? day.openTime : null,
            'close_time': day.isOpen ? day.closeTime : null,
            'timezone': _business?.timezone ?? 'UTC',
          },
          onConflict: _progress.branchId != null
              ? 'branch_id,day_of_week'
              : 'business_id,day_of_week',
        );
      }

      _markCompleted(OnboardingStep.businessHours);
      return true;
    } on PostgrestException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Step 7: Booking Settings ──────────────────────────────────────────────

  void updateBookingSettings(OnboardingBookingSettings settings) {
    _bookingSettings = settings;
    notifyListeners();
  }

  Future<bool> saveBookingSettings() async {
    if (_progress.businessId == null) {
      _setError('Business must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      final orgId = _progress.organizationId!;
      final bizId = _progress.businessId!;
      final s = _bookingSettings;

      // Upsert booking_settings
      await _client.from('booking_settings').upsert({
        'organization_id': orgId,
        'business_id': bizId,
        'online_booking_enabled': s.onlineBookingEnabled,
        'min_advance_booking_value': s.minAdvanceBookingHours,
        'min_advance_booking_unit': 'hours',
        'max_advance_booking_value': s.maxAdvanceBookingDays,
        'max_advance_booking_unit': 'days',
        'auto_confirm': s.autoConfirm,
        'requires_approval': !s.autoConfirm,
        'allow_guest_booking': s.allowGuestBooking,
        'show_employee_selection': s.showEmployeeSelection,
        'show_price': s.showPrice,
      }, onConflict: 'business_id,branch_id');

      // Upsert cancellation_policies
      await _client.from('cancellation_policies').upsert({
        'organization_id': orgId,
        'business_id': bizId,
        'cancellation_enabled': s.cancellationEnabled,
        'min_notice_value': s.minCancellationNoticeHours,
        'min_notice_unit': 'hours',
        'rescheduling_enabled': s.reschedulingEnabled,
        'min_reschedule_notice_value': s.minCancellationNoticeHours,
        'min_reschedule_notice_unit': 'hours',
      }, onConflict: 'business_id,branch_id');

      _markCompleted(OnboardingStep.bookingSettings);
      return true;
    } on PostgrestException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Step 8: Publish ───────────────────────────────────────────────────────

  Future<bool> publishBusiness() async {
    if (_progress.businessId == null) {
      _setError('Business must be created first.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      final result = await _businessRepository.publishBusiness(
        _progress.businessId!,
      );
      return result.fold(
        onSuccess: (biz) {
          _business = biz;
          notifyListeners();
          return true;
        },
        onFailure: (f) {
          _setError(f.message);
          return false;
        },
      );
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void goToStep(OnboardingStep step) {
    _progress = _progress.copyWith(currentStep: step);
    notifyListeners();
  }

  void completeStep(OnboardingStep step) {
    _markCompleted(step);
    final next = _nextStep(step);
    if (next != null) {
      _progress = _progress.copyWith(currentStep: next);
    }
    notifyListeners();
  }

  void clearError() => _clearError();

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _markCompleted(OnboardingStep step) {
    final completed = {..._progress.completedSteps, step};
    _progress = _progress.copyWith(completedSteps: completed);
  }

  OnboardingStep? _nextStep(OnboardingStep current) {
    final steps = OnboardingStep.values;
    final idx = steps.indexOf(current);
    if (idx < steps.length - 1) return steps[idx + 1];
    return null;
  }

  OnboardingStep _firstIncompleteStep() {
    for (final step in OnboardingStep.values) {
      if (!_progress.isStepCompleted(step)) return step;
    }
    return OnboardingStep.review;
  }

  // ─── Data loaders ──────────────────────────────────────────────────────────

  Future<void> _loadServices() async {
    if (_progress.businessId == null) return;
    try {
      final response = await _client
          .from('services')
          .select()
          .eq('business_id', _progress.businessId!)
          .isFilter('deleted_at', null)
          .order('created_at');

      _services = (response as List<dynamic>).map((row) {
        final m = row as Map<String, dynamic>;
        return OnboardingServiceEntity(
          id: m['id'] as String,
          name: m['name'] as String,
          description: m['description'] as String?,
          durationMins: m['duration_mins'] as int? ?? 60,
          bufferBeforeMins: m['buffer_before_mins'] as int? ?? 0,
          bufferAfterMins: m['buffer_after_mins'] as int? ?? 0,
          price: (m['price'] as num?)?.toDouble() ?? 0.0,
          currency: m['currency'] as String? ?? 'USD',
          isActive: (m['status'] as String?) == 'active',
        );
      }).toList();

      if (_services.isNotEmpty) {
        _markCompleted(OnboardingStep.services);
      }
    } catch (e) {
      AppLogger.warning('_loadServices failed: $e', tag: 'OnboardingProvider');
    }
  }

  Future<void> _loadEmployees() async {
    if (_progress.businessId == null) return;
    try {
      final response = await _client
          .from('employees')
          .select('*, employee_services(service_id)')
          .eq('business_id', _progress.businessId!)
          .isFilter('deleted_at', null)
          .order('created_at');

      _employees = (response as List<dynamic>).map((row) {
        final m = row as Map<String, dynamic>;
        final svcList =
            (m['employee_services'] as List<dynamic>?)
                ?.map(
                  (e) => (e as Map<String, dynamic>)['service_id'] as String,
                )
                .toList() ??
            [];
        return OnboardingEmployeeEntity(
          id: m['id'] as String,
          firstName: m['first_name'] as String,
          lastName: m['last_name'] as String? ?? '',
          email: m['email'] as String?,
          phone: m['phone'] as String?,
          avatarUrl: m['avatar_url'] as String?,
          isActive: (m['status'] as String?) == 'active',
          isBookable: m['is_bookable'] as bool? ?? true,
          serviceIds: svcList,
        );
      }).toList();

      if (_employees.isNotEmpty) {
        _markCompleted(OnboardingStep.employees);
      }
    } catch (e) {
      AppLogger.warning('_loadEmployees failed: $e', tag: 'OnboardingProvider');
    }
  }

  Future<void> _loadBusinessHours() async {
    if (_progress.businessId == null) return;
    try {
      final response = await _client
          .from('business_hours')
          .select()
          .eq('business_id', _progress.businessId!)
          .order('day_of_week');

      if ((response as List<dynamic>).isEmpty) return;

      const dayMap = {
        'sunday': 0,
        'monday': 1,
        'tuesday': 2,
        'wednesday': 3,
        'thursday': 4,
        'friday': 5,
        'saturday': 6,
      };

      final loaded = <OnboardingDayHours>[];
      for (final row in response) {
        final m = row;
        final dayEnum = m['day_of_week'] as String;
        final dayIdx = dayMap[dayEnum] ?? 0;
        loaded.add(
          OnboardingDayHours(
            dayOfWeek: dayIdx,
            isOpen: m['is_open'] as bool? ?? true,
            openTime: m['open_time'] as String? ?? '09:00',
            closeTime: m['close_time'] as String? ?? '17:00',
          ),
        );
      }

      if (loaded.length == 7) {
        _businessHours = loaded;
        _markCompleted(OnboardingStep.businessHours);
      }
    } catch (e) {
      AppLogger.warning(
        '_loadBusinessHours failed: $e',
        tag: 'OnboardingProvider',
      );
    }
  }

  Future<void> _loadBookingSettings() async {
    if (_progress.businessId == null) return;
    try {
      final response = await _client
          .from('booking_settings')
          .select()
          .eq('business_id', _progress.businessId!)
          .isFilter('branch_id', null)
          .maybeSingle();

      if (response == null) return;

      final m = response;
      _bookingSettings = OnboardingBookingSettings(
        onlineBookingEnabled: m['online_booking_enabled'] as bool? ?? true,
        minAdvanceBookingHours: m['min_advance_booking_value'] as int? ?? 1,
        maxAdvanceBookingDays: m['max_advance_booking_value'] as int? ?? 30,
        autoConfirm: m['auto_confirm'] as bool? ?? true,
        allowGuestBooking: m['allow_guest_booking'] as bool? ?? true,
        showEmployeeSelection: m['show_employee_selection'] as bool? ?? true,
        showPrice: m['show_price'] as bool? ?? true,
      );
      _markCompleted(OnboardingStep.bookingSettings);
    } catch (e) {
      AppLogger.warning(
        '_loadBookingSettings failed: $e',
        tag: 'OnboardingProvider',
      );
    }
  }

  static List<OnboardingDayHours> _defaultBusinessHours() {
    return List.generate(7, (i) {
      final isWeekend = i == 0 || i == 6;
      return OnboardingDayHours(
        dayOfWeek: i,
        isOpen: !isWeekend,
        openTime: '09:00',
        closeTime: '17:00',
      );
    });
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  @override
  void dispose() {
    _orgRepository.dispose();
    _businessRepository.dispose();
    super.dispose();
  }
}
