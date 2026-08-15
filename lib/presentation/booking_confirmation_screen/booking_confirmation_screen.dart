import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../navigation/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../features/public_booking/domain/repositories/public_booking_repository.dart';
import '../../features/public_booking/presentation/providers/public_booking_provider.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String slug;
  final String token;

  const BookingConfirmationScreen({
    required this.slug,
    required this.token,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<PublicBookingProvider>();
    final result = booking.bookingResult;

    // If no booking result in state (e.g., direct URL navigation), redirect to management
    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/appointments/$token');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Booking Confirmed',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Success header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Appointment Booked!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your appointment has been successfully scheduled.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appointment details
                _DetailsCard(result: result),

                const SizedBox(height: 20),

                // Token reference
                Container(
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
                        'Appointment Reference',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          token,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Save this reference to manage or cancel your appointment.',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final cancelToken = result.cancellationToken ?? '';
                      context.go('/appointments/$token?ct=$cancelToken');
                    },
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Manage Appointment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/b/$slug'),
                    child: const Text('Back to Business'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(RouteNames.publicSearch),
                  child: const Text('Find Another Business'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final PublicBookingResult result;

  const _DetailsCard({required this.result});

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
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.storefront_outlined,
            label: 'Business',
            value: result.businessName,
          ),
          _DetailRow(
            icon: Icons.spa_outlined,
            label: 'Service',
            value: result.serviceName,
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat(
              'EEEE, MMMM d, y',
            ).format(result.startTime.toLocal()),
          ),
          _DetailRow(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value:
                '${DateFormat('h:mm a').format(result.startTime.toLocal())} – ${DateFormat('h:mm a').format(result.endTime.toLocal())}',
          ),
          if (result.employeeName != null)
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Staff',
              value: result.employeeName!,
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