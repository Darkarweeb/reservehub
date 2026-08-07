import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import './settings_section_base.dart';

class SettingsBusinessProfileWidget extends StatefulWidget {
  const SettingsBusinessProfileWidget({super.key});

  @override
  State<SettingsBusinessProfileWidget> createState() =>
      _SettingsBusinessProfileWidgetState();
}

class _SettingsBusinessProfileWidgetState
    extends State<SettingsBusinessProfileWidget> {
  // TODO: Replace with Riverpod BusinessProfileNotifier for production
  final _nameCtrl = TextEditingController(text: 'Bella Salon & Spa');
  final _phoneCtrl = TextEditingController(text: '+1 (305) 555-0100');
  final _emailCtrl = TextEditingController(text: 'info@bellasalon.com');
  final _addressCtrl = TextEditingController(
    text: '1420 Brickell Ave, Miami, FL 33131',
  );
  final _bioCtrl = TextEditingController(
    text:
        'Premium salon & spa offering a full range of beauty services in the heart of Miami.',
  );

  String _selectedCategory = 'Hair Salon';
  String _selectedTimezone = 'America/New_York';

  static const List<String> _categories = [
    'Hair Salon',
    'Barbershop',
    'Nail Salon',
    'Spa',
    'Medical Clinic',
    'Gym',
    'Wellness Center',
    'Dental',
    'Veterinary',
    'Coaching',
  ];

  static const List<String> _timezones = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Sao_Paulo',
    'Europe/London',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionWrapper(
      title: 'Business Profile',
      icon: Icons.business_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomImageWidget(
                  imageUrl:
                      'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Bella Salon and Spa business logo showing elegant salon interior',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Logo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG or SVG. Max 2MB.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_rounded, size: 14),
                      label: Text(
                        'Upload Logo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        side: const BorderSide(color: AppTheme.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Business Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.business_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Business Category'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined, size: 18),
              filled: true,
              fillColor: AppTheme.surfaceVariantLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.outlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.outlineLight),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedCategory = v ?? _selectedCategory),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Phone'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Address'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressCtrl,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Timezone'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedTimezone,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.public_outlined, size: 18),
              filled: true,
              fillColor: AppTheme.surfaceVariantLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.outlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.outlineLight),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: _timezones
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedTimezone = v ?? _selectedTimezone),
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Business Description'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }
}

class _SettingsSectionWrapper extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSectionWrapper({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionBase(title: title, icon: icon, child: child);
  }
}
