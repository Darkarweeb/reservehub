import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../navigation/route_names.dart';
import '../../../shared/utils/responsive_builder.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/media_image_widget.dart';
import '../../features/media/presentation/providers/media_provider.dart';
import '../../features/public_booking/presentation/providers/public_booking_provider.dart';
import '../../features/public_discovery/domain/repositories/public_discovery_repository.dart';
import '../../features/public_discovery/presentation/providers/public_discovery_provider.dart';

class BookingFlowScreen extends StatefulWidget {
  final String slug;

  const BookingFlowScreen({required this.slug, super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discoveryProvider = context.read<PublicDiscoveryProvider>();
      final bookingProvider = context.read<PublicBookingProvider>();

      bookingProvider.initFlow(widget.slug);

      if (discoveryProvider.profile?.slug != widget.slug) {
        discoveryProvider.loadProfile(widget.slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Consumer2<PublicDiscoveryProvider, MediaProvider>(
          builder: (context, provider, media, _) {
            final profile = provider.profile;
            final logoUrl = profile?.id != null
                ? media.getBusinessLogo(profile!.id)?.publicUrl
                : null;
            return Row(
              children: [
                if (logoUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: MediaImageWidget(
                      imageUrl: logoUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (profile != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    profile?.name ?? 'Book Appointment',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/b/${widget.slug}'),
        ),
      ),
      body: Consumer2<PublicDiscoveryProvider, PublicBookingProvider>(
        builder: (context, discovery, booking, _) {
          if (discovery.profileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = discovery.profile;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Business not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(RouteNames.publicSearch),
                    child: const Text('Back to Search'),
                  ),
                ],
              ),
            );
          }

          return _BookingFlowContent(
            profile: profile,
            booking: booking,
            slug: widget.slug,
          );
        },
      ),
    );
  }
}

class _BookingFlowContent extends StatelessWidget {
  final PublicBusinessProfile profile;
  final PublicBookingProvider booking;
  final String slug;

  const _BookingFlowContent({
    required this.profile,
    required this.booking,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    // Load business media when content is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final media = context.read<MediaProvider>();
      media.loadBusinessMedia(profile.id);
    });

    return ResponsiveBuilder(
      builder: (context, size) {
        final content = _stepContent(context);
        if (size == ScreenSize.desktop) {
          return Row(
            children: [
              SizedBox(
                width: 240,
                child: _StepSidebar(
                  currentStep: booking.currentStep,
                  selections: booking.selections,
                  profile: profile,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: content,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StepProgressBar(currentStep: booking.currentStep),
              const SizedBox(height: 16),
              content,
            ],
          ),
        );
      },
    );
  }

  Widget _stepContent(BuildContext context) {
    switch (booking.currentStep) {
      case BookingStep.branch:
        return _BranchStep(profile: profile, booking: booking);
      case BookingStep.service:
        return _ServiceStep(profile: profile, booking: booking);
      case BookingStep.employee:
        return _EmployeeStep(booking: booking);
      case BookingStep.dateTime:
        return _DateTimeStep(booking: booking);
      case BookingStep.customerInfo:
        return _CustomerInfoStep(booking: booking, slug: slug);
      case BookingStep.confirmation:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step Sidebar (Desktop) ───────────────────────────────────────────────────

class _StepSidebar extends StatelessWidget {
  final BookingStep currentStep;
  final BookingSelections selections;
  final PublicBusinessProfile? profile;

  const _StepSidebar({
    required this.currentStep,
    required this.selections,
    this.profile,
  });

  static const _steps = [
    (BookingStep.branch, 'Branch', Icons.place_outlined),
    (BookingStep.service, 'Service', Icons.spa_outlined),
    (BookingStep.employee, 'Staff', Icons.person_outline),
    (BookingStep.dateTime, 'Date & Time', Icons.calendar_today_outlined),
    (BookingStep.customerInfo, 'Your Info', Icons.person_pin_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business branding in sidebar
          if (profile != null) ...[
            Consumer<MediaProvider>(
              builder: (context, media, _) {
                final logoUrl = media.getBusinessLogo(profile!.id)?.publicUrl;
                final coverUrl = media.getBusinessCover(profile!.id)?.publicUrl;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (coverUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: MediaImageWidget(
                          imageUrl: coverUrl,
                          width: double.infinity,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        BusinessLogoWidget(
                          logoUrl: logoUrl,
                          businessName: profile!.name,
                          size: 36,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile!.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
          Text(
            'Booking Steps',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.map((s) {
            final (step, label, icon) = s;
            final isActive = step == currentStep;
            final isDone = step.index < currentStep.index;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success
                          : isActive
                          ? AppColors.secondary
                          : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : icon,
                      size: 14,
                      color: isDone || isActive ? Colors.white : Colors.black45,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? AppColors.secondary
                          : isDone
                          ? Colors.black54
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step Progress Bar (Mobile) ───────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final BookingStep currentStep;

  const _StepProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final total = BookingStep.values.length - 1; // exclude confirmation
    final current = currentStep.index.clamp(0, total - 1);
    return Column(
      children: [
        LinearProgressIndicator(
          value: (current + 1) / total,
          backgroundColor: Colors.black12,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${current + 1} of $total',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

// ─── Step: Branch ─────────────────────────────────────────────────────────────

class _BranchStep extends StatelessWidget {
  final PublicBusinessProfile profile;
  final PublicBookingProvider booking;

  const _BranchStep({required this.profile, required this.booking});

  @override
  Widget build(BuildContext context) {
    if (profile.branches.length == 1) {
      // Auto-select single branch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        booking.selectBranch(
          profile.branches.first.id,
          profile.branches.first.name,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _StepCard(
      title: 'Select a Location',
      subtitle: 'Choose the branch you\'d like to visit',
      child: Consumer<MediaProvider>(
        builder: (context, media, _) {
          return Column(
            children: profile.branches.map((b) {
              final branchCoverUrl = media.getBranchCover(b.id)?.publicUrl;
              return _BranchSelectionTile(
                branch: b,
                imageUrl: branchCoverUrl,
                onTap: () => booking.selectBranch(b.id, b.name),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BranchSelectionTile extends StatelessWidget {
  final PublicBranchInfo branch;
  final String? imageUrl;
  final VoidCallback onTap;

  const _BranchSelectionTile({
    required this.branch,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MediaImageWidget(
                imageUrl: imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                fallback: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    size: 22,
                    color: AppColors.secondary,
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
                    branch.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (branch.city != null)
                    Text(
                      branch.city!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step: Service ────────────────────────────────────────────────────────────

class _ServiceStep extends StatelessWidget {
  final PublicBusinessProfile profile;
  final PublicBookingProvider booking;

  const _ServiceStep({required this.profile, required this.booking});

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      title: 'Select a Service',
      subtitle: 'What would you like to book?',
      onBack: () => booking.goToStep(BookingStep.branch),
      child: Consumer<MediaProvider>(
        builder: (context, media, _) {
          return Column(
            children: profile.services.map((s) {
              final serviceImage = media.getServiceImage(s.id)?.publicUrl;
              return _ServiceSelectionTile(
                service: s,
                imageUrl: serviceImage,
                onTap: () => booking.selectService(
                  serviceId: s.id,
                  serviceName: s.name,
                  durationMins: s.durationMinutes,
                  price: s.price,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ServiceSelectionTile extends StatelessWidget {
  final PublicServiceInfo service;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ServiceSelectionTile({
    required this.service,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MediaImageWidget(
                imageUrl: imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                fallback: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    size: 22,
                    color: AppColors.secondary,
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
                    service.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${service.durationMinutes} min${service.price > 0 ? ' · \$${service.price.toStringAsFixed(0)}' : ''}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step: Employee ───────────────────────────────────────────────────────────

class _EmployeeStep extends StatelessWidget {
  final PublicBookingProvider booking;

  const _EmployeeStep({required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.employeesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _StepCard(
      title: 'Select Staff',
      subtitle: 'Choose who you\'d like to see',
      onBack: () => booking.goToStep(BookingStep.service),
      child: Column(
        children: [
          if (booking.employees.isNotEmpty)
            _SelectionTile(
              title: 'No preference',
              subtitle: 'We\'ll assign the next available staff',
              icon: Icons.shuffle_outlined,
              onTap: () => booking.selectEmployee(
                booking.employees.first.id,
                'Any available',
              ),
            ),
          ...booking.employees.map(
            (e) => _SelectionTile(
              title: e.name,
              subtitle: e.title,
              icon: Icons.person_outline,
              onTap: () => booking.selectEmployee(e.id, e.name),
            ),
          ),
          if (booking.employees.isEmpty && booking.employeesError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                booking.employeesError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step: Date & Time ────────────────────────────────────────────────────────

class _DateTimeStep extends StatelessWidget {
  final PublicBookingProvider booking;

  const _DateTimeStep({required this.booking});

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      title: 'Select Date & Time',
      subtitle: 'Choose when you\'d like to come in',
      onBack: () => booking.goToStep(BookingStep.employee),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DatePicker(booking: booking),
          if (booking.selections.selectedDate != null) ...[
            const SizedBox(height: 16),
            _TimeSlotPicker(booking: booking),
          ],
          if (booking.selections.selectedSlot != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: booking.proceedToCustomerInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final PublicBookingProvider booking;

  const _DatePicker({required this.booking});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selected = booking.selections.selectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a date',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 30,
            itemBuilder: (context, i) {
              final date = now.add(Duration(days: i + 1));
              final isSelected =
                  selected != null &&
                  selected.year == date.year &&
                  selected.month == date.month &&
                  selected.day == date.day;
              return GestureDetector(
                onTap: () => booking.selectDate(date),
                child: Container(
                  width: 52,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.secondary : Colors.black12,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimeSlotPicker extends StatelessWidget {
  final PublicBookingProvider booking;

  const _TimeSlotPicker({required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.slotsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (booking.slotsError != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          booking.slotsError!,
          style: const TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (booking.availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'No available times on this date.',
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available times',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: booking.availableSlots.map((slot) {
            final isSelected = booking.selections.selectedSlot == slot;
            return GestureDetector(
              onTap: () => booking.selectSlot(slot),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : Colors.black12,
                  ),
                ),
                child: Text(
                  DateFormat('h:mm a').format(slot.toLocal()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Step: Customer Info ──────────────────────────────────────────────────────

class _CustomerInfoStep extends StatefulWidget {
  final PublicBookingProvider booking;
  final String slug;

  const _CustomerInfoStep({required this.booking, required this.slug});

  @override
  State<_CustomerInfoStep> createState() => _CustomerInfoStepState();
}

class _CustomerInfoStepState extends State<_CustomerInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    widget.booking.updateCustomerInfo(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    final success = await widget.booking.submitBooking();
    if (success && mounted) {
      final token = widget.booking.bookingResult?.bookingToken ?? '';
      context.go('/b/${widget.slug}/appointment/$token');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final sel = booking.selections;

    return _StepCard(
      title: 'Your Information',
      subtitle: 'Almost done! Tell us how to reach you.',
      onBack: () => booking.goToStep(BookingStep.dateTime),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sel.serviceName != null)
                    _SummaryRow(
                      icon: Icons.spa_outlined,
                      text: sel.serviceName!,
                    ),
                  if (sel.branchName != null)
                    _SummaryRow(
                      icon: Icons.place_outlined,
                      text: sel.branchName!,
                    ),
                  if (sel.selectedSlot != null)
                    _SummaryRow(
                      icon: Icons.access_time_outlined,
                      text: DateFormat(
                        'EEE, MMM d · h:mm a',
                      ).format(sel.selectedSlot!.toLocal()),
                    ),
                  if (sel.employeeName != null)
                    _SummaryRow(
                      icon: Icons.person_outline,
                      text: sel.employeeName!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _BookingTextField(
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'Your full name',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _BookingTextField(
              controller: _emailCtrl,
              label: 'Email Address',
              hint: 'your@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _BookingTextField(
              controller: _phoneCtrl,
              label: 'Phone (optional)',
              hint: '+1 555 000 0000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _BookingTextField(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              hint: 'Any special requests or notes',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (booking.bookingError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.bookingError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: booking.bookingLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: booking.bookingLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _BookingTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

// ─── Shared Step Card ─────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

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
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: Colors.black45),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ),
          if (onBack != null) const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
