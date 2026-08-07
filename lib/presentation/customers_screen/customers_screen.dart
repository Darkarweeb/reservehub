import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/customer_filter_widget.dart';
import './widgets/customer_list_item_widget.dart';
import './widgets/customer_search_bar_widget.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  // TODO: Replace with Riverpod CustomersNotifier for production
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _allCustomers = [
    {
      'id': 'cust001',
      'name': 'Isabela Ferreira',
      'phone': '+1 (305) 555-0142',
      'email': 'isabela.f@gmail.com',
      'lastVisit': '2026-08-05',
      'totalSpent': 1240.0,
      'visits': 18,
      'tier': 'VIP',
      'status': 'Active',
      'tags': ['Regular', 'Color'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1acd899c5-1772561408162.png',
      'avatarLabel': 'Young Brazilian woman with long wavy dark hair smiling',
      'loyaltyPoints': 620,
    },
    {
      'id': 'cust002',
      'name': 'Priya Sharma',
      'phone': '+1 (786) 555-0219',
      'email': 'priya.s@outlook.com',
      'lastVisit': '2026-08-07',
      'totalSpent': 845.0,
      'visits': 12,
      'tier': 'Gold',
      'status': 'Active',
      'tags': ['Nails', 'Waxing'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19205d2aa-1763296356182.png',
      'avatarLabel':
          'Indian woman with dark hair and warm smile in professional setting',
      'loyaltyPoints': 422,
    },
    {
      'id': 'cust003',
      'name': 'Carlos Mendoza',
      'phone': '+1 (954) 555-0387',
      'email': 'c.mendoza@email.com',
      'lastVisit': '2026-08-07',
      'totalSpent': 530.0,
      'visits': 8,
      'tier': 'Silver',
      'status': 'Active',
      'tags': ['Haircut', 'Beard'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18d6b3d42-1763294255023.png',
      'avatarLabel': 'Hispanic man with short dark hair and neat beard',
      'loyaltyPoints': 265,
    },
    {
      'id': 'cust004',
      'name': 'Yuki Tanaka',
      'phone': '+1 (305) 555-0498',
      'email': 'yuki.t@icloud.com',
      'lastVisit': '2026-07-14',
      'totalSpent': 1890.0,
      'visits': 24,
      'tier': 'VIP',
      'status': 'At-Risk',
      'tags': ['Color', 'Highlights'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1d2e1ee84-1772642997684.png',
      'avatarLabel':
          'Japanese woman with straight black hair and subtle elegant style',
      'loyaltyPoints': 945,
    },
    {
      'id': 'cust005',
      'name': 'Aisha Johnson',
      'phone': '+1 (786) 555-0561',
      'email': 'aisha.j@gmail.com',
      'lastVisit': '2026-08-03',
      'totalSpent': 420.0,
      'visits': 5,
      'tier': 'Silver',
      'status': 'Active',
      'tags': ['Massage', 'Facial'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_185d73bc8-1772147601277.png',
      'avatarLabel':
          'African American woman with natural hair and bright confident smile',
      'loyaltyPoints': 210,
    },
    {
      'id': 'cust006',
      'name': 'Marcus Williams',
      'phone': '+1 (954) 555-0634',
      'email': 'm.williams@email.com',
      'lastVisit': '2026-08-01',
      'totalSpent': 195.0,
      'visits': 2,
      'tier': 'Bronze',
      'status': 'New',
      'tags': ['Scalp Treatment'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18947de05-1763295449747.png',
      'avatarLabel':
          'African American man with short hair in casual comfortable attire',
      'loyaltyPoints': 97,
    },
    {
      'id': 'cust007',
      'name': 'Fatima Al-Hassan',
      'phone': '+1 (305) 555-0712',
      'email': 'fatima.ah@gmail.com',
      'lastVisit': '2026-07-28',
      'totalSpent': 2340.0,
      'visits': 31,
      'tier': 'VIP',
      'status': 'Active',
      'tags': ['Bridal', 'Color', 'Cuts'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1fa32ffc4-1763297920492.png',
      'avatarLabel':
          'Middle Eastern woman with elegant styling and graceful expression',
      'loyaltyPoints': 1170,
    },
    {
      'id': 'cust008',
      'name': 'Elena Popescu',
      'phone': '+1 (786) 555-0823',
      'email': 'elena.p@outlook.com',
      'lastVisit': '2026-06-15',
      'totalSpent': 760.0,
      'visits': 9,
      'tier': 'Gold',
      'status': 'At-Risk',
      'tags': ['Facial', 'Waxing'],
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1654ece41-1763298416069.png',
      'avatarLabel':
          'Romanian woman with fair skin and light brown shoulder-length hair',
      'loyaltyPoints': 380,
    },
  ];

  List<Map<String, dynamic>> get _filteredCustomers {
    return _allCustomers.where((c) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (c['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (c['email'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (c['phone'] as String).contains(_searchQuery);
      final matchesFilter =
          _selectedFilter == 'All' ||
          c['status'] == _selectedFilter ||
          c['tier'] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final filtered = _filteredCustomers;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed chrome: search + filters
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Customers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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
                      '${_allCustomers.length} total',
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomerSearchBarWidget(
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ),
            const SizedBox(height: 10),
            CustomerFilterWidget(
              selected: _selectedFilter,
              onSelected: (f) => setState(() => _selectedFilter = f),
            ),
            const SizedBox(height: 12),
            // Scrollable list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.secondary,
                child: filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: 'No customers found',
                        subtitle:
                            'Try adjusting your search or filters, or add a new customer.',
                        ctaLabel: 'Add Customer',
                        onCta: () {},
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => CustomerListItemWidget(
                          customer: filtered[i],
                          index: i,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'Add Customer',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
