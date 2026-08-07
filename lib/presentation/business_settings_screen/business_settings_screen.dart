import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';
import './widgets/settings_business_profile_widget.dart';
import './widgets/settings_danger_zone_widget.dart';
import './widgets/settings_notifications_widget.dart';
import './widgets/settings_services_widget.dart';
import './widgets/settings_subscription_widget.dart';
import './widgets/settings_working_hours_widget.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  // TODO: Replace with Riverpod SettingsNotifier for production
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBarWidget(
        title: 'Business Settings',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SettingsBusinessProfileWidget(),
              SizedBox(height: 20),
              SettingsWorkingHoursWidget(),
              SizedBox(height: 20),
              SettingsServicesWidget(),
              SizedBox(height: 20),
              SettingsNotificationsWidget(),
              SizedBox(height: 20),
              SettingsSubscriptionWidget(),
              SizedBox(height: 20),
              SettingsDangerZoneWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
