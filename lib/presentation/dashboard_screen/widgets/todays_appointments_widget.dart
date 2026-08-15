import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../localization/app_strings.dart';
import '../../../widgets/status_badge_widget.dart';

class TodaysAppointmentsWidget extends StatelessWidget {
  TodaysAppointmentsWidget({super.key});

  final List<Map<String, dynamic>> _appointments = [
    {
      'customerName': 'Priya Sharma',
      'service': 'Gel Manicure',
      'time': '10:00 AM',
      'duration': '45 min',
      'employee': 'Ana Lima',
      'status': 'completed',
      'price': '\$65',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19205d2aa-1763296356182.png',
      'avatarLabel':
          'Indian woman with dark hair smiling warmly in professional setting',
    },
    {
      'customerName': 'Carlos Mendoza',
      'service': 'Haircut + Beard',
      'time': '11:30 AM',
      'duration': '60 min',
      'employee': 'Rafael Souza',
      'status': 'confirmed',
      'price': '\$85',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1556846d3-1763294180620.png',
      'avatarLabel':
          'Hispanic man with short dark hair and beard in casual attire',
    },
    {
      'customerName': 'Aisha Johnson',
      'service': 'Deep Tissue Massage',
      'time': '1:00 PM',
      'duration': '90 min',
      'employee': 'Sofia Mendes',
      'status': 'checked_in',
      'price': '\$140',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_185d73bc8-1772147601277.png',
      'avatarLabel':
          'African American woman with natural hair smiling confidently',
    },
    {
      'customerName': 'Yuki Tanaka',
      'service': 'Full Highlights',
      'time': '3:00 PM',
      'duration': '120 min',
      'employee': 'Sofia Mendes',
      'status': 'no_show',
      'price': '\$220',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18c3b1bd5-1772679076808.png',
      'avatarLabel': 'Japanese woman with straight black hair and subtle smile',
    },
  ];

  AppointmentStatus _statusFromString(String s) {
    switch (s) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'checked_in':
        return AppointmentStatus.checkedIn;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.horarioDeHoy,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_appointments.length} ${AppStrings.totalLabel}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _appointments.length,
            (i) => _AppointmentListItem(
              data: _appointments[i],
              status: _statusFromString(_appointments[i]['status'] as String),
              index: i,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentListItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final AppointmentStatus status;
  final int index;

  const _AppointmentListItem({
    required this.data,
    required this.status,
    required this.index,
  });

  @override
  State<_AppointmentListItem> createState() => _AppointmentListItemState();
}

class _AppointmentListItemState extends State<_AppointmentListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariantLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Time column
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data['time'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      widget.data['duration'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomImageWidget(
                  imageUrl: widget.data['avatarUrl'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  semanticLabel: widget.data['avatarLabel'] as String,
                ),
              ),
              const SizedBox(width: 10),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data['customerName'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.data['service']} · ${widget.data['employee']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.data['price'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadgeWidget(status: widget.status, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
