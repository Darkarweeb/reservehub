import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../features/management/domain/entities/management_entities.dart';
import '../../features/management/presentation/providers/management_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/customer_filter_widget.dart';
import './widgets/customer_search_bar_widget.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  CustomerCrmEntity? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagementProvider>();
      provider.initialize().then((_) => provider.loadCustomers());
    });
  }

  void _onSearch(String q) {
    setState(() => _searchQuery = q);
    final provider = context.read<ManagementProvider>();
    provider.loadCustomers(
      search: q.isEmpty ? null : q,
      status: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
    );
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    final provider = context.read<ManagementProvider>();
    provider.loadCustomers(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: filter == 'All' ? null : filter.toLowerCase(),
    );
  }

  Future<void> _onRefresh() async {
    final provider = context.read<ManagementProvider>();
    await provider.loadCustomers(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        final customers = provider.customers;
        final isLoading = provider.customersLoading;

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: SafeArea(
            child: Column(
              children: [
                // Header
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
                          '${provider.customersTotal} total',
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
                  child: CustomerSearchBarWidget(onChanged: _onSearch),
                ),
                const SizedBox(height: 10),
                CustomerFilterWidget(
                  selected: _selectedFilter,
                  onSelected: _onFilterChanged,
                ),
                const SizedBox(height: 12),
                // List
                Expanded(
                  child: isLoading && customers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : customers.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          title: 'No customers found',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Customers will appear here after their first booking',
                        )
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          color: AppTheme.secondary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            itemCount: customers.length,
                            itemBuilder: (context, i) {
                              final c = customers[i];
                              return _CustomerCrmCard(
                                customer: c,
                                isSelected: _selectedCustomer?.id == c.id,
                                onTap: () => setState(() {
                                  _selectedCustomer =
                                      _selectedCustomer?.id == c.id ? null : c;
                                }),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Customer CRM Card ────────────────────────────────────────────────────────

class _CustomerCrmCard extends StatelessWidget {
  final CustomerCrmEntity customer;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerCrmCard({
    required this.customer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.secondaryContainer : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.secondary.withAlpha(120)
              : AppTheme.outlineLight,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.secondaryContainer,
                    backgroundImage: customer.avatarUrl != null
                        ? NetworkImage(customer.avatarUrl!)
                        : null,
                    child: customer.avatarUrl == null
                        ? Text(
                            customer.displayName.isNotEmpty
                                ? customer.displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer.email != null)
                          Text(
                            customer.email!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: customer.isActive
                          ? AppTheme.successContainer
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: customer.isActive
                            ? AppTheme.success
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.calendar_today_outlined,
                    label: '${customer.totalVisits} visits',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.attach_money_rounded,
                    label: '\$${customer.totalSpent.toStringAsFixed(0)}',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.star_outline_rounded,
                    label: '${customer.loyaltyPoints} pts',
                  ),
                  if (customer.lastVisitAt != null) ...[
                    const Spacer(),
                    Text(
                      _fmtDate(customer.lastVisitAt!),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
              if (customer.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: customer.tags
                      .take(4)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
