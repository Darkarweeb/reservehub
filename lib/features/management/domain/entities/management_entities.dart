/// Domain entities for the Business Management layer.
library;

// ─── Dashboard KPIs ───────────────────────────────────────────────────────────

class DashboardKpiEntity {
  final int todayCount;
  final int yesterdayCount;
  final int upcomingCount;
  final int completedCount;
  final int cancelledCount;
  final int customerCount;
  final double appointmentValue;
  final DateTime date;

  const DashboardKpiEntity({
    required this.todayCount,
    required this.yesterdayCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.customerCount,
    required this.appointmentValue,
    required this.date,
  });

  int get todayDelta => todayCount - yesterdayCount;
  bool get isTodayUp => todayDelta >= 0;
}

// ─── Customer CRM ─────────────────────────────────────────────────────────────

class CustomerCrmEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String status;
  final int totalVisits;
  final double totalSpent;
  final int loyaltyPoints;
  final DateTime? lastVisitAt;
  final List<String> tags;
  final DateTime createdAt;

  const CustomerCrmEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.status,
    required this.totalVisits,
    required this.totalSpent,
    required this.loyaltyPoints,
    this.lastVisitAt,
    required this.tags,
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  factory CustomerCrmEntity.fromJson(Map<String, dynamic> json) {
    return CustomerCrmEntity(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      displayName:
          json['display_name'] as String? ??
          '${json['first_name']} ${json['last_name']}',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      totalVisits: (json['total_visits'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      lastVisitAt: json['last_visit_at'] != null
          ? DateTime.parse(json['last_visit_at'] as String)
          : null,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Business Hours ───────────────────────────────────────────────────────────

class BusinessHourEntity {
  final String? id;
  final String dayOfWeek;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String timezone;

  const BusinessHourEntity({
    this.id,
    required this.dayOfWeek,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.timezone = 'UTC',
  });

  BusinessHourEntity copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return BusinessHourEntity(
      id: id,
      dayOfWeek: dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      timezone: timezone,
    );
  }

  factory BusinessHourEntity.fromJson(Map<String, dynamic> json) {
    return BusinessHourEntity(
      id: json['id'] as String?,
      dayOfWeek: json['day_of_week'] as String,
      isOpen: json['is_open'] as bool? ?? true,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'is_open': isOpen,
    'open_time': openTime,
    'close_time': closeTime,
    'timezone': timezone,
  };
}

// ─── Employee Working Hours ───────────────────────────────────────────────────

class EmployeeWorkingHourEntity {
  final String? id;
  final String dayOfWeek;
  final bool isWorking;
  final String? startTime;
  final String? endTime;
  final String timezone;

  const EmployeeWorkingHourEntity({
    this.id,
    required this.dayOfWeek,
    required this.isWorking,
    this.startTime,
    this.endTime,
    this.timezone = 'UTC',
  });

  EmployeeWorkingHourEntity copyWith({
    bool? isWorking,
    String? startTime,
    String? endTime,
  }) {
    return EmployeeWorkingHourEntity(
      id: id,
      dayOfWeek: dayOfWeek,
      isWorking: isWorking ?? this.isWorking,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone,
    );
  }

  factory EmployeeWorkingHourEntity.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkingHourEntity(
      id: json['id'] as String?,
      dayOfWeek: json['day_of_week'] as String,
      isWorking: json['is_working'] as bool? ?? true,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'is_working': isWorking,
    'start_time': startTime,
    'end_time': endTime,
    'timezone': timezone,
  };
}

// ─── Employee Break ───────────────────────────────────────────────────────────

class EmployeeBreakEntity {
  final String id;
  final String employeeId;
  final String breakName;
  final String? dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  const EmployeeBreakEntity({
    required this.id,
    required this.employeeId,
    required this.breakName,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory EmployeeBreakEntity.fromJson(Map<String, dynamic> json) {
    return EmployeeBreakEntity(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      breakName: json['break_name'] as String? ?? 'Break',
      dayOfWeek: json['day_of_week'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

// ─── Employee Time Off ────────────────────────────────────────────────────────

class EmployeeTimeOffEntity {
  final String id;
  final String employeeId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String? reason;
  final String timeOffType;
  final String status;

  const EmployeeTimeOffEntity({
    required this.id,
    required this.employeeId,
    required this.startDatetime,
    required this.endDatetime,
    this.reason,
    required this.timeOffType,
    required this.status,
  });

  factory EmployeeTimeOffEntity.fromJson(Map<String, dynamic> json) {
    return EmployeeTimeOffEntity(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      reason: json['reason'] as String?,
      timeOffType: json['time_off_type'] as String? ?? 'unavailable',
      status: json['status'] as String? ?? 'approved',
    );
  }
}

// ─── Schedule Exception ───────────────────────────────────────────────────────

class ScheduleExceptionEntity {
  final String id;
  final DateTime exceptionDate;
  final String exceptionType;
  final bool isClosed;
  final String? openTime;
  final String? closeTime;
  final String? reason;

  const ScheduleExceptionEntity({
    required this.id,
    required this.exceptionDate,
    required this.exceptionType,
    required this.isClosed,
    this.openTime,
    this.closeTime,
    this.reason,
  });

  factory ScheduleExceptionEntity.fromJson(Map<String, dynamic> json) {
    return ScheduleExceptionEntity(
      id: json['id'] as String,
      exceptionDate: DateTime.parse(json['exception_date'] as String),
      exceptionType: json['exception_type'] as String? ?? 'modified_hours',
      isClosed: json['is_closed'] as bool? ?? false,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

// ─── Booking Settings ─────────────────────────────────────────────────────────

class BookingSettingsEntity {
  final String? id;
  final bool onlineBookingEnabled;
  final bool guestBookingEnabled;
  final bool autoConfirm;
  final int minBookingNoticeHours;
  final int maxBookingHorizonDays;
  final int slotDurationMinutes;
  final bool allowRescheduling;
  final int rescheduleNoticeHours;
  final int maxReschedules;
  // Cancellation policy
  final bool cancellationAllowed;
  final int cancellationNoticeHours;
  final double cancellationFee;
  final double noShowFee;
  final String? policyText;

  const BookingSettingsEntity({
    this.id,
    this.onlineBookingEnabled = true,
    this.guestBookingEnabled = true,
    this.autoConfirm = false,
    this.minBookingNoticeHours = 1,
    this.maxBookingHorizonDays = 60,
    this.slotDurationMinutes = 30,
    this.allowRescheduling = true,
    this.rescheduleNoticeHours = 24,
    this.maxReschedules = 2,
    this.cancellationAllowed = true,
    this.cancellationNoticeHours = 24,
    this.cancellationFee = 0,
    this.noShowFee = 0,
    this.policyText,
  });

  factory BookingSettingsEntity.fromJson(
    Map<String, dynamic> settings,
    Map<String, dynamic>? policy,
  ) {
    return BookingSettingsEntity(
      id: settings['id'] as String?,
      onlineBookingEnabled: settings['online_booking_enabled'] as bool? ?? true,
      guestBookingEnabled: settings['guest_booking_enabled'] as bool? ?? true,
      autoConfirm: settings['auto_confirm'] as bool? ?? false,
      minBookingNoticeHours:
          (settings['min_booking_notice_hours'] as num?)?.toInt() ?? 1,
      maxBookingHorizonDays:
          (settings['max_booking_horizon_days'] as num?)?.toInt() ?? 60,
      slotDurationMinutes:
          (settings['slot_duration_minutes'] as num?)?.toInt() ?? 30,
      allowRescheduling: settings['allow_rescheduling'] as bool? ?? true,
      rescheduleNoticeHours:
          (settings['reschedule_notice_hours'] as num?)?.toInt() ?? 24,
      maxReschedules: (settings['max_reschedules'] as num?)?.toInt() ?? 2,
      cancellationAllowed: policy?['cancellation_allowed'] as bool? ?? true,
      cancellationNoticeHours:
          (policy?['cancellation_notice_hours'] as num?)?.toInt() ?? 24,
      cancellationFee: (policy?['cancellation_fee'] as num?)?.toDouble() ?? 0,
      noShowFee: (policy?['no_show_fee'] as num?)?.toDouble() ?? 0,
      policyText: policy?['policy_text'] as String?,
    );
  }

  BookingSettingsEntity copyWith({
    bool? onlineBookingEnabled,
    bool? guestBookingEnabled,
    bool? autoConfirm,
    int? minBookingNoticeHours,
    int? maxBookingHorizonDays,
    int? slotDurationMinutes,
    bool? allowRescheduling,
    int? rescheduleNoticeHours,
    int? maxReschedules,
    bool? cancellationAllowed,
    int? cancellationNoticeHours,
    double? cancellationFee,
    double? noShowFee,
    String? policyText,
  }) {
    return BookingSettingsEntity(
      id: id,
      onlineBookingEnabled: onlineBookingEnabled ?? this.onlineBookingEnabled,
      guestBookingEnabled: guestBookingEnabled ?? this.guestBookingEnabled,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      minBookingNoticeHours:
          minBookingNoticeHours ?? this.minBookingNoticeHours,
      maxBookingHorizonDays:
          maxBookingHorizonDays ?? this.maxBookingHorizonDays,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      allowRescheduling: allowRescheduling ?? this.allowRescheduling,
      rescheduleNoticeHours:
          rescheduleNoticeHours ?? this.rescheduleNoticeHours,
      maxReschedules: maxReschedules ?? this.maxReschedules,
      cancellationAllowed: cancellationAllowed ?? this.cancellationAllowed,
      cancellationNoticeHours:
          cancellationNoticeHours ?? this.cancellationNoticeHours,
      cancellationFee: cancellationFee ?? this.cancellationFee,
      noShowFee: noShowFee ?? this.noShowFee,
      policyText: policyText ?? this.policyText,
    );
  }
}

// ─── Management Employee (richer than EmployeeEntity) ────────────────────────

class ManagementEmployeeEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? title;
  final String status;
  final bool isBookable;
  final String? color;
  final DateTime createdAt;

  const ManagementEmployeeEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.title,
    required this.status,
    required this.isBookable,
    this.color,
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  factory ManagementEmployeeEntity.fromJson(Map<String, dynamic> json) {
    return ManagementEmployeeEntity(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      displayName:
          json['display_name'] as String? ??
          '${json['first_name']} ${json['last_name']}',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      title: json['title'] as String?,
      status: json['status'] as String? ?? 'active',
      isBookable: json['is_bookable'] as bool? ?? true,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Management Service ───────────────────────────────────────────────────────

class ManagementServiceEntity {
  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final int bufferBeforeMinutes;
  final int bufferAfterMinutes;
  final bool isActive;
  final String? colorHex;
  final String? category;

  const ManagementServiceEntity({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.bufferBeforeMinutes = 0,
    this.bufferAfterMinutes = 0,
    required this.isActive,
    this.colorHex,
    this.category,
  });

  factory ManagementServiceEntity.fromJson(Map<String, dynamic> json) {
    return ManagementServiceEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      bufferBeforeMinutes:
          (json['buffer_before_minutes'] as num?)?.toInt() ?? 0,
      bufferAfterMinutes: (json['buffer_after_minutes'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      colorHex: json['color_hex'] as String?,
      category: json['category'] as String?,
    );
  }
}

// ─── Management Branch ────────────────────────────────────────────────────────

class ManagementBranchEntity {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? email;
  final String? timezone;
  final bool isActive;
  final DateTime createdAt;

  const ManagementBranchEntity({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.email,
    this.timezone,
    required this.isActive,
    required this.createdAt,
  });

  factory ManagementBranchEntity.fromJson(Map<String, dynamic> json) {
    return ManagementBranchEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      timezone: json['timezone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
