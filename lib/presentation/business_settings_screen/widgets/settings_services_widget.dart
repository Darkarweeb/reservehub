import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class SettingsServicesWidget extends StatefulWidget {
  const SettingsServicesWidget({super.key});

  @override
  State<SettingsServicesWidget> createState() => _SettingsServicesWidgetState();
}

class _SettingsServicesWidgetState extends State<SettingsServicesWidget> {
  // TODO: Replace with Riverpod ServicesNotifier for production
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Haircut & Style',
      'duration': '45 min',
      'price': 65,
      'active': true,
    },
    {
      'name': 'Balayage + Cut',
      'duration': '90 min',
      'price': 185,
      'active': true,
    },
    {'name': 'Gel Manicure', 'duration': '45 min', 'price': 65, 'active': true},
    {
      'name': 'Deep Tissue Massage',
      'duration': '90 min',
      'price': 140,
      'active': false,
    },
    {
      'name': 'Classic Facial',
      'duration': '60 min',
      'price': 110,
      'active': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Services & Pricing',
      icon: Icons.spa_outlined,
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(
          'Add Service',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(foregroundColor: AppTheme.secondary),
      ),
      child: Column(
        children: List.generate(_services.length, (i) {
          final svc = _services[i];
          final isActive = svc['active'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariantLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        svc['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.primary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            svc['duration'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${svc['price']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) => setState(() => _services[i]['active'] = v),
                  activeThumbColor: AppTheme.secondary,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
