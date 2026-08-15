import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../navigation/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../features/media/presentation/providers/media_provider.dart';
import '../../features/public_booking/domain/repositories/public_booking_repository.dart';
import '../../features/public_booking/presentation/providers/public_booking_provider.dart';

class AppointmentManagementScreen extends StatefulWidget {
  final String token;
  final String? cancelToken;

  const AppointmentManagementScreen({
    required this.token,
    this.cancelToken,
    super.key,
  });

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicBookingProvider>().loadAppointmentByToken(
        widget.token,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Consumer<PublicBookingProvider>(
          builder: (context, provider, _) {
            final appt = provider.appointmentResult;
            return Text(
              appt?.businessName ?? 'My Appointment',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.publicSearch),
        ),
      ),
      body: Consumer<PublicBookingProvider>(
        builder: (context, provider, _) {
          if (provider.appointmentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.appointmentError != null) {
            return _ErrorView(message: provider.appointmentError!);
          }

          final appt = provider.appointmentResult;
          if (appt == null) {
            return const _ErrorView(
              message: 'Appointment not found. The link may be invalid.',
            );
          }

          return _AppointmentContent(
            appt: appt,
            token: widget.token,
            cancelToken: widget.cancelToken,
            provider: provider,
          );
        },
      ),
    );
  }
}

class _AppointmentContent extends StatelessWidget {
  final AppointmentTokenResult appt;
  final String token;
  final String? cancelToken;
  final PublicBookingProvider provider;

  const _AppointmentContent({
    required this.appt,
    required this.token,
    this.cancelToken,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = appt.status == 'cancelled';
    final isPast = appt.endTime.isBefore(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              // Business branding header
              _BusinessBrandingHeader(businessName: appt.businessName),
              const SizedBox(height: 16),

              // Status badge
              _StatusBanner(status: appt.status),
              const SizedBox(height: 20),

              // Details card
              _AppointmentDetailsCard(appt: appt),
              const SizedBox(height: 20),

              // Cancel section
              if (!isCancelled && !isPast)
                _CancelSection(
                  token: token,
                  cancelToken: cancelToken,
                  provider: provider,
                ),

              if (isCancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This appointment has been cancelled.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go(RouteNames.publicSearch),
                child: const Text('Find Another Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Business branding header shown on the appointment management screen.
class _BusinessBrandingHeader extends StatelessWidget {
  final String businessName;

  const _BusinessBrandingHeader({required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, media, _) {
        // We don't have businessId here directly, so we look through cached media
        // for a logo matching this business name. If not found, show text fallback.
        // The media is loaded when the booking flow loads the business profile.
        // For the appointment token screen, we show a branded header with the name.
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    businessName.isNotEmpty
                        ? businessName[0].toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Appointment Confirmation',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  'ReserveHub',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon, label) = switch (status) {
      'confirmed' => (
        AppColors.success,
        AppColors.successContainer,
        Icons.check_circle_outline,
        'Confirmed',
      ),
      'pending' => (
        AppColors.warning,
        AppColors.warningContainer,
        Icons.schedule_outlined,
        'Pending Confirmation',
      ),
      'cancelled' => (
        AppColors.error,
        AppColors.errorContainer,
        Icons.cancel_outlined,
        'Cancelled',
      ),
      'completed' => (
        AppColors.info,
        AppColors.infoContainer,
        Icons.task_alt_outlined,
        'Completed',
      ),
      _ => (
        Colors.black54,
        Colors.black12,
        Icons.info_outline,
        status.toUpperCase(),
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailsCard extends StatelessWidget {
  final AppointmentTokenResult appt;

  const _AppointmentDetailsCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.storefront_outlined,
            label: 'Business',
            value: appt.businessName,
          ),
          if (appt.branchName != null)
            _DetailRow(
              icon: Icons.place_outlined,
              label: 'Location',
              value: appt.branchName!,
            ),
          _DetailRow(
            icon: Icons.spa_outlined,
            label: 'Service',
            value: appt.serviceName,
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat(
              'EEEE, MMMM d, y',
            ).format(appt.startTime.toLocal()),
          ),
          _DetailRow(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value:
                '${DateFormat('h:mm a').format(appt.startTime.toLocal())} – ${DateFormat('h:mm a').format(appt.endTime.toLocal())}',
          ),
          if (appt.employeeName != null && appt.employeeName!.isNotEmpty)
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Staff',
              value: appt.employeeName!,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelSection extends StatefulWidget {
  final String token;
  final String? cancelToken;
  final PublicBookingProvider provider;

  const _CancelSection({
    required this.token,
    this.cancelToken,
    required this.provider,
  });

  @override
  State<_CancelSection> createState() => _CancelSectionState();
}

class _CancelSectionState extends State<_CancelSection> {
  bool _showConfirm = false;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.provider.cancelSuccess) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Appointment cancelled successfully.',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need to Cancel?',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can cancel your appointment if it\'s within the cancellation window.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          if (widget.provider.cancelError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.provider.cancelError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!_showConfirm)
            OutlinedButton.icon(
              onPressed: () => setState(() => _showConfirm = true),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Cancel Appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            )
          else ...[
            TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Why are you cancelling?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showConfirm = false),
                    child: const Text('Keep Appointment'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.provider.cancelLoading
                        ? null
                        : () => widget.provider.cancelAppointment(
                            widget.cancelToken ?? widget.token,
                            reason: _reasonCtrl.text.trim().isEmpty
                                ? null
                                : _reasonCtrl.text.trim(),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: widget.provider.cancelLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.publicSearch),
              child: const Text('Back to Search'),
            ),
          ],
        ),
      ),
    );
  }
}
