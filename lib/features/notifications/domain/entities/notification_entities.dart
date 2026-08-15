/// Domain entities for the Notification Engine.
library;

// ─── Notification Preferences Entity ─────────────────────────────────────────

class NotificationPreferencesEntity {
  final String? id;
  final String? businessId;
  final bool dailySummaryEnabled;
  final bool appointmentNotificationsEnabled;
  final bool newAppointmentEmailEnabled;
  final bool cancellationEmailEnabled;
  final bool reminderEmailEnabled;
  final String dailySummarySendTime;
  final String? summaryRecipientEmail;

  const NotificationPreferencesEntity({
    this.id,
    this.businessId,
    this.dailySummaryEnabled = true,
    this.appointmentNotificationsEnabled = true,
    this.newAppointmentEmailEnabled = true,
    this.cancellationEmailEnabled = true,
    this.reminderEmailEnabled = true,
    this.dailySummarySendTime = '07:00:00',
    this.summaryRecipientEmail,
  });

  factory NotificationPreferencesEntity.defaults() {
    return const NotificationPreferencesEntity();
  }

  factory NotificationPreferencesEntity.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesEntity(
      id: json['id'] as String?,
      businessId: json['business_id'] as String?,
      dailySummaryEnabled: json['daily_summary_enabled'] as bool? ?? true,
      appointmentNotificationsEnabled:
          json['appointment_notifications_enabled'] as bool? ?? true,
      newAppointmentEmailEnabled:
          json['new_appointment_email_enabled'] as bool? ?? true,
      cancellationEmailEnabled:
          json['cancellation_email_enabled'] as bool? ?? true,
      reminderEmailEnabled: json['reminder_email_enabled'] as bool? ?? true,
      dailySummarySendTime:
          json['daily_summary_send_time'] as String? ?? '07:00:00',
      summaryRecipientEmail: json['summary_recipient_email'] as String?,
    );
  }

  NotificationPreferencesEntity copyWith({
    bool? dailySummaryEnabled,
    bool? appointmentNotificationsEnabled,
    bool? newAppointmentEmailEnabled,
    bool? cancellationEmailEnabled,
    bool? reminderEmailEnabled,
    String? summaryRecipientEmail,
  }) {
    return NotificationPreferencesEntity(
      id: id,
      businessId: businessId,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      appointmentNotificationsEnabled:
          appointmentNotificationsEnabled ??
          this.appointmentNotificationsEnabled,
      newAppointmentEmailEnabled:
          newAppointmentEmailEnabled ?? this.newAppointmentEmailEnabled,
      cancellationEmailEnabled:
          cancellationEmailEnabled ?? this.cancellationEmailEnabled,
      reminderEmailEnabled: reminderEmailEnabled ?? this.reminderEmailEnabled,
      dailySummarySendTime: dailySummarySendTime,
      summaryRecipientEmail:
          summaryRecipientEmail ?? this.summaryRecipientEmail,
    );
  }
}

// ─── Notification Queue Item Entity ──────────────────────────────────────────

class NotificationQueueItemEntity {
  final String id;
  final String event;
  final String channel;
  final String recipientType;
  final String? recipientEmail;
  final String? recipientName;
  final String deliveryStatus;
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? failureReason;
  final int attemptCount;
  final String? providerMessageId;
  final DateTime createdAt;

  const NotificationQueueItemEntity({
    required this.id,
    required this.event,
    required this.channel,
    required this.recipientType,
    this.recipientEmail,
    this.recipientName,
    required this.deliveryStatus,
    required this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.failureReason,
    required this.attemptCount,
    this.providerMessageId,
    required this.createdAt,
  });

  factory NotificationQueueItemEntity.fromJson(Map<String, dynamic> json) {
    return NotificationQueueItemEntity(
      id: json['id'] as String,
      event: json['event'] as String? ?? '',
      channel: json['channel'] as String? ?? 'email',
      recipientType: json['recipient_type'] as String? ?? 'customer',
      recipientEmail: json['recipient_email'] as String?,
      recipientName: json['recipient_name'] as String?,
      deliveryStatus: json['delivery_status'] as String? ?? 'pending',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      failureReason: json['failure_reason'] as String?,
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      providerMessageId: json['provider_message_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isSent => deliveryStatus == 'sent' || deliveryStatus == 'delivered';
  bool get isFailed =>
      deliveryStatus == 'failed' || deliveryStatus == 'bounced';
  bool get isPending =>
      deliveryStatus == 'pending' || deliveryStatus == 'queued';
}
