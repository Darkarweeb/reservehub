import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../core/di/service_locator.dart';
import '../../../features/management/presentation/providers/management_provider.dart';

class SettingsBusinessProfileWidget extends StatefulWidget {
  const SettingsBusinessProfileWidget({super.key});

  @override
  State<SettingsBusinessProfileWidget> createState() =>
      _SettingsBusinessProfileWidgetState();
}

class _SettingsBusinessProfileWidgetState
    extends State<SettingsBusinessProfileWidget> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String _selectedTimezone = 'UTC';
  bool _loaded = false;
  bool _saving = false;

  static const List<String> _timezones = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Sao_Paulo',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
    'Asia/Dubai',
    'Australia/Sydney',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBusinessData());
  }

  Future<void> _loadBusinessData() async {
    if (_loaded) return;
    final provider = context.read<ManagementProvider>();
    if (provider.businessId == null) {
      await provider.initialize();
    }
    final bizId = provider.businessId;
    if (bizId == null) return;

    try {
      final client = provider;
      // Load business data directly
      final supabase = ServiceLocator.get<SupabaseClient>();
      final data = await supabase
          .from('businesses')
          .select()
          .eq('id', bizId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameCtrl.text = data['name'] as String? ?? '';
          _phoneCtrl.text = data['phone'] as String? ?? '';
          _emailCtrl.text = data['email'] as String? ?? '';
          _websiteCtrl.text = data['website'] as String? ?? '';
          _addressCtrl.text = data['address'] as String? ?? '';
          _cityCtrl.text = data['city'] as String? ?? '';
          _countryCtrl.text = data['country'] as String? ?? '';
          _bioCtrl.text = data['description'] as String? ?? '';
          final tz = data['timezone'] as String? ?? 'UTC';
          _selectedTimezone = _timezones.contains(tz) ? tz : 'UTC';
          _loaded = true;
        });
      }
    } catch (e) {
      // Silently fail — form stays empty for user to fill
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<ManagementProvider>();
    final result = await provider.updateBusinessProfile(
      name: _nameCtrl.text.trim(),
      description: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      timezone: _selectedTimezone,
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim().isEmpty
          ? null
          : _countryCtrl.text.trim(),
    );
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated'),
          backgroundColor: AppTheme.success,
        ),
      ),
      onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message ?? 'Failed to save'),
          backgroundColor: AppTheme.error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionWrapper(
      title: 'Business Profile',
      icon: Icons.business_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildFieldLabel('Description'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Describe your business...',
            ),
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
          _buildFieldLabel('Website'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _websiteCtrl,
            keyboardType: TextInputType.url,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.language_outlined, size: 18),
              hintText: 'https://',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('City'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cityCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Country'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _countryCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.flag_outlined, size: 18),
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
                        prefixIcon: const Icon(
                          Icons.access_time_outlined,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariantLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineLight,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _timezones
                          .map(
                            (tz) => DropdownMenuItem(
                              value: tz,
                              child: Text(tz, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _selectedTimezone = v ?? _selectedTimezone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondary,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Business Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.secondary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
