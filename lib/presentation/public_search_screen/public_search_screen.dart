import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/utils/responsive_builder.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/media_image_widget.dart';
import '../../features/public_discovery/domain/repositories/public_discovery_repository.dart';
import '../../features/public_discovery/presentation/providers/public_discovery_provider.dart';

class BusinessSearchScreen extends StatefulWidget {
  const BusinessSearchScreen({super.key});

  @override
  State<BusinessSearchScreen> createState() => _BusinessSearchScreenState();
}

class _BusinessSearchScreenState extends State<BusinessSearchScreen> {
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicDiscoveryProvider>().search();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _doSearch() {
    context.read<PublicDiscoveryProvider>().search(
      query: _searchController.text.trim(),
      city: _cityController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _SearchAppBar(
            searchController: _searchController,
            cityController: _cityController,
            onSearch: _doSearch,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _SearchResults(onSearch: _doSearch),
        ],
      ),
    );
  }
}

class _SearchAppBar extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController cityController;
  final VoidCallback onSearch;

  const _SearchAppBar({
    required this.searchController,
    required this.cityController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Find a Business',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover and book appointments near you',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(
                    searchController: searchController,
                    cityController: cityController,
                    onSearch: onSearch,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController cityController;
  final VoidCallback onSearch;

  const _SearchBar({
    required this.searchController,
    required this.cityController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size == ScreenSize.desktop) {
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: _SearchField(
                  controller: searchController,
                  hint: 'Search businesses...',
                  icon: Icons.search,
                  onSubmit: onSearch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _SearchField(
                  controller: cityController,
                  hint: 'City',
                  icon: Icons.location_on_outlined,
                  onSubmit: onSearch,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('Search'),
              ),
            ],
          );
        }
        return Column(
          children: [
            _SearchField(
              controller: searchController,
              hint: 'Search businesses...',
              icon: Icons.search,
              onSubmit: onSearch,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: cityController,
                    hint: 'City',
                    icon: Icons.location_on_outlined,
                    onSubmit: onSearch,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final VoidCallback onSubmit;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withAlpha(38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final VoidCallback onSearch;

  const _SearchResults({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Consumer<PublicDiscoveryProvider>(
      builder: (context, provider, _) {
        if (provider.searchLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.searchError != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.searchError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onSearch,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.searchResults.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 64,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No businesses found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try a different search term or location',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 200,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  _BusinessCard(business: provider.searchResults[i]),
              childCount: provider.searchResults.length,
            ),
          ),
        );
      },
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final PublicBusinessResult business;

  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/b/${business.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover / logo area
            Container(
              height: 80,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaImageWidget(
                      imageUrl: business.logoUrl,
                      fit: BoxFit.cover,
                      fallback: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            business.name.isNotEmpty
                                ? business.name[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (business.categoryName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      business.categoryName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (business.city != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            business.city!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBusinessIcon extends StatelessWidget {
  const _DefaultBusinessIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.storefront_outlined,
        size: 36,
        color: AppColors.secondary,
      ),
    );
  }
}
