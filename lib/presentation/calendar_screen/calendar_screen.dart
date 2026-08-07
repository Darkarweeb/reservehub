import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/calendar_appointment_list_widget.dart';
import './widgets/calendar_grid_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // TODO: Replace with Riverpod CalendarNotifier for production
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isLoading = false);
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
  }

  void _onMonthChanged(DateTime month) {
    setState(() => _focusedMonth = month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBarWidget(
        title: 'Calendar',
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.today_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedMonth = DateTime.now();
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.secondary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CalendarGridWidget(
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  onDaySelected: _onDaySelected,
                  onMonthChanged: _onMonthChanged,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        _formatSelectedDay(_selectedDay),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Spacer(),
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
                          '${_getAppointmentsForDay(_selectedDay).length} appts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _getAppointmentsForDay(_selectedDay).isEmpty
                  ? SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.event_available_rounded,
                        title: 'No appointments',
                        subtitle:
                            'This day is free. Add an appointment to fill the schedule.',
                        ctaLabel: 'New Appointment',
                        onCta: () {},
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: CalendarAppointmentListWidget(
                        appointments: _getAppointmentsForDay(_selectedDay),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSelectedDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    // TODO: Replace with Riverpod CalendarNotifier filtering for production
    final today = DateTime.now();
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final isTomorrow =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day + 1;

    if (isToday) return _todayAppointments;
    if (isTomorrow) return _tomorrowAppointments;
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return [];
    }
    return _defaultAppointments;
  }

  final List<Map<String, dynamic>> _todayAppointments = [
    {
      'id': 'apt001',
      'customerName': 'Priya Sharma',
      'service': 'Gel Manicure',
      'time': '10:00',
      'duration': '45 min',
      'employee': 'Ana Lima',
      'status': 'completed',
      'price': 65,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1ae8ac9a7-1773218303784.png',
      'avatarLabel': 'Indian woman with dark hair in salon setting',
    },
    {
      'id': 'apt002',
      'customerName': 'Carlos Mendoza',
      'service': 'Haircut + Beard',
      'time': '11:30',
      'duration': '60 min',
      'employee': 'Rafael Souza',
      'status': 'confirmed',
      'price': 85,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_138df7967-1763295321074.png',
      'avatarLabel': 'Hispanic man with short hair and well-groomed beard',
    },
    {
      'id': 'apt003',
      'customerName': 'Aisha Johnson',
      'service': 'Deep Tissue Massage',
      'time': '13:00',
      'duration': '90 min',
      'employee': 'Sofia Mendes',
      'status': 'checked_in',
      'price': 140,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_12bbf7f12-1772647621786.png',
      'avatarLabel': 'African American woman with natural hair smiling',
    },
    {
      'id': 'apt004',
      'customerName': 'Yuki Tanaka',
      'service': 'Full Highlights',
      'time': '15:00',
      'duration': '120 min',
      'employee': 'Sofia Mendes',
      'status': 'no_show',
      'price': 220,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_13a87048b-1772827297136.png',
      'avatarLabel': 'Japanese woman with straight black hair',
    },
  ];

  final List<Map<String, dynamic>> _tomorrowAppointments = [
    {
      'id': 'apt005',
      'customerName': 'Fatima Al-Hassan',
      'service': 'Bridal Makeup',
      'time': '09:00',
      'duration': '120 min',
      'employee': 'Ana Lima',
      'status': 'confirmed',
      'price': 280,
      'avatarUrl':
          'https://images.unsplash.com/photo-1728413272542-8f111669099a',
      'avatarLabel': 'Middle Eastern woman with elegant makeup and hijab',
    },
    {
      'id': 'apt006',
      'customerName': 'Marcus Williams',
      'service': 'Scalp Treatment',
      'time': '11:00',
      'duration': '60 min',
      'employee': 'Rafael Souza',
      'status': 'pending',
      'price': 95,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18947de05-1763295449747.png',
      'avatarLabel': 'African American man with short hair in casual clothes',
    },
  ];

  final List<Map<String, dynamic>> _defaultAppointments = [
    {
      'id': 'apt007',
      'customerName': 'Elena Popescu',
      'service': 'Classic Facial',
      'time': '10:30',
      'duration': '60 min',
      'employee': 'Ana Lima',
      'status': 'confirmed',
      'price': 110,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1654ece41-1763298416069.png',
      'avatarLabel': 'Romanian woman with fair skin and light brown hair',
    },
    {
      'id': 'apt008',
      'customerName': 'Raj Patel',
      'service': 'Sports Massage',
      'time': '14:00',
      'duration': '75 min',
      'employee': 'Sofia Mendes',
      'status': 'pending',
      'price': 120,
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15fd8f0f7-1763295595860.png',
      'avatarLabel': 'Indian man with dark hair wearing business casual attire',
    },
  ];
}
