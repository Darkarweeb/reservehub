/// Business onboarding domain entities and step definitions.
library;

/// Represents the current step in the onboarding flow.
enum OnboardingStep {
  organization,
  business,
  branch,
  services,
  employees,
  businessHours,
  bookingSettings,
  review,
}

extension OnboardingStepX on OnboardingStep {
  String get title {
    switch (this) {
      case OnboardingStep.organization:
        return 'Organization';
      case OnboardingStep.business:
        return 'Business';
      case OnboardingStep.branch:
        return 'Branch';
      case OnboardingStep.services:
        return 'Services';
      case OnboardingStep.employees:
        return 'Employees';
      case OnboardingStep.businessHours:
        return 'Business Hours';
      case OnboardingStep.bookingSettings:
        return 'Booking Settings';
      case OnboardingStep.review:
        return 'Review & Publish';
    }
  }

  String get subtitle {
    switch (this) {
      case OnboardingStep.organization:
        return 'Tell us about your organization';
      case OnboardingStep.business:
        return 'Set up your business profile';
      case OnboardingStep.branch:
        return 'Add your first location';
      case OnboardingStep.services:
        return 'Define what you offer';
      case OnboardingStep.employees:
        return 'Add your team members';
      case OnboardingStep.businessHours:
        return 'Set your operating hours';
      case OnboardingStep.bookingSettings:
        return 'Configure booking rules';
      case OnboardingStep.review:
        return 'Review and publish your business';
    }
  }

  int get index => OnboardingStep.values.indexOf(this);
}

/// Onboarding progress state.
class OnboardingProgressEntity {
  final String? userId;
  final String? organizationId;
  final String? businessId;
  final String? branchId;
  final OnboardingStep currentStep;
  final Set<OnboardingStep> completedSteps;

  const OnboardingProgressEntity({
    this.userId,
    this.organizationId,
    this.businessId,
    this.branchId,
    this.currentStep = OnboardingStep.organization,
    this.completedSteps = const {},
  });

  bool isStepCompleted(OnboardingStep step) => completedSteps.contains(step);

  double get progressPercent =>
      completedSteps.length / OnboardingStep.values.length;

  OnboardingProgressEntity copyWith({
    String? userId,
    String? organizationId,
    String? businessId,
    String? branchId,
    OnboardingStep? currentStep,
    Set<OnboardingStep>? completedSteps,
  }) {
    return OnboardingProgressEntity(
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

/// Service entity for onboarding.
class OnboardingServiceEntity {
  final String? id;
  final String name;
  final String? description;
  final int durationMins;
  final int bufferBeforeMins;
  final int bufferAfterMins;
  final double price;
  final String currency;
  final bool isActive;

  const OnboardingServiceEntity({
    this.id,
    required this.name,
    this.description,
    this.durationMins = 60,
    this.bufferBeforeMins = 0,
    this.bufferAfterMins = 0,
    this.price = 0.0,
    this.currency = 'USD',
    this.isActive = true,
  });

  OnboardingServiceEntity copyWith({
    String? id,
    String? name,
    String? description,
    int? durationMins,
    int? bufferBeforeMins,
    int? bufferAfterMins,
    double? price,
    String? currency,
    bool? isActive,
  }) {
    return OnboardingServiceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMins: durationMins ?? this.durationMins,
      bufferBeforeMins: bufferBeforeMins ?? this.bufferBeforeMins,
      bufferAfterMins: bufferAfterMins ?? this.bufferAfterMins,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Employee entity for onboarding.
class OnboardingEmployeeEntity {
  final String? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final bool isBookable;
  final List<String> serviceIds;

  const OnboardingEmployeeEntity({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.isBookable = true,
    this.serviceIds = const [],
  });

  String get displayName => '$firstName $lastName'.trim();

  OnboardingEmployeeEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    bool? isBookable,
    List<String>? serviceIds,
  }) {
    return OnboardingEmployeeEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      isBookable: isBookable ?? this.isBookable,
      serviceIds: serviceIds ?? this.serviceIds,
    );
  }
}

/// Business hours for a single day.
class OnboardingDayHours {
  final int dayOfWeek; // 0=Sunday ... 6=Saturday
  final bool isOpen;
  final String openTime; // HH:mm
  final String closeTime; // HH:mm

  const OnboardingDayHours({
    required this.dayOfWeek,
    this.isOpen = true,
    this.openTime = '09:00',
    this.closeTime = '17:00',
  });

  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[dayOfWeek % 7];
  }

  OnboardingDayHours copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return OnboardingDayHours(
      dayOfWeek: dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

/// Working hours for a single day (employee).
class OnboardingWorkingHours {
  final int dayOfWeek;
  final bool isWorking;
  final String startTime;
  final String endTime;

  const OnboardingWorkingHours({
    required this.dayOfWeek,
    this.isWorking = true,
    this.startTime = '09:00',
    this.endTime = '17:00',
  });

  OnboardingWorkingHours copyWith({
    bool? isWorking,
    String? startTime,
    String? endTime,
  }) {
    return OnboardingWorkingHours(
      dayOfWeek: dayOfWeek,
      isWorking: isWorking ?? this.isWorking,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// Booking settings entity for onboarding.
class OnboardingBookingSettings {
  final bool onlineBookingEnabled;
  final int minAdvanceBookingHours;
  final int maxAdvanceBookingDays;
  final bool autoConfirm;
  final bool allowGuestBooking;
  final bool showEmployeeSelection;
  final bool showPrice;
  final bool cancellationEnabled;
  final int minCancellationNoticeHours;
  final bool reschedulingEnabled;

  const OnboardingBookingSettings({
    this.onlineBookingEnabled = true,
    this.minAdvanceBookingHours = 1,
    this.maxAdvanceBookingDays = 30,
    this.autoConfirm = true,
    this.allowGuestBooking = true,
    this.showEmployeeSelection = true,
    this.showPrice = true,
    this.cancellationEnabled = true,
    this.minCancellationNoticeHours = 24,
    this.reschedulingEnabled = true,
  });

  OnboardingBookingSettings copyWith({
    bool? onlineBookingEnabled,
    int? minAdvanceBookingHours,
    int? maxAdvanceBookingDays,
    bool? autoConfirm,
    bool? allowGuestBooking,
    bool? showEmployeeSelection,
    bool? showPrice,
    bool? cancellationEnabled,
    int? minCancellationNoticeHours,
    bool? reschedulingEnabled,
  }) {
    return OnboardingBookingSettings(
      onlineBookingEnabled: onlineBookingEnabled ?? this.onlineBookingEnabled,
      minAdvanceBookingHours:
          minAdvanceBookingHours ?? this.minAdvanceBookingHours,
      maxAdvanceBookingDays:
          maxAdvanceBookingDays ?? this.maxAdvanceBookingDays,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      allowGuestBooking: allowGuestBooking ?? this.allowGuestBooking,
      showEmployeeSelection:
          showEmployeeSelection ?? this.showEmployeeSelection,
      showPrice: showPrice ?? this.showPrice,
      cancellationEnabled: cancellationEnabled ?? this.cancellationEnabled,
      minCancellationNoticeHours:
          minCancellationNoticeHours ?? this.minCancellationNoticeHours,
      reschedulingEnabled: reschedulingEnabled ?? this.reschedulingEnabled,
    );
  }
}

/// Working hours entity (kept for backward compatibility).
class WorkingHoursEntity {
  final String id;
  final String organizationId;
  final String? businessId;
  final String? branchId;
  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isOpen;

  const WorkingHoursEntity({
    required this.id,
    required this.organizationId,
    this.businessId,
    this.branchId,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    this.isOpen = true,
  });

  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[dayOfWeek % 7];
  }
}

/// Booking settings entity (kept for backward compatibility).
class BookingSettingsEntity {
  final String id;
  final String organizationId;
  final String? businessId;
  final String? branchId;
  final int advanceBookingDays;
  final int minNoticeHours;
  final int slotIntervalMinutes;
  final bool allowGuestBooking;
  final bool requireConfirmation;
  final bool cancellationEnabled;
  final int? minCancellationNoticeHours;

  const BookingSettingsEntity({
    required this.id,
    required this.organizationId,
    this.businessId,
    this.branchId,
    this.advanceBookingDays = 30,
    this.minNoticeHours = 1,
    this.slotIntervalMinutes = 30,
    this.allowGuestBooking = true,
    this.requireConfirmation = false,
    this.cancellationEnabled = true,
    this.minCancellationNoticeHours,
  });
}
