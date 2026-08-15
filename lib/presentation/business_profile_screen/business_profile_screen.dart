import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../navigation/route_names.dart';
import '../../../shared/utils/responsive_builder.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/media_image_widget.dart';
import '../../features/media/presentation/providers/media_provider.dart';
import '../../features/public_discovery/domain/repositories/public_discovery_repository.dart';
import '../../features/public_discovery/presentation/providers/public_discovery_provider.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String slug;

  const BusinessProfileScreen({required this.slug, super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicDiscoveryProvider>().loadProfile(widget.slug).then((
        _,
      ) {
        final profile = context.read<PublicDiscoveryProvider>().profile;
        if (profile != null) {
          context.read<MediaProvider>().loadBusinessMedia(profile.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Consumer<PublicDiscoveryProvider>(
        builder: (context, provider, _) {
          if (provider.profileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profileError != null) {
            return _ErrorView(
              message: provider.profileError!,
              onRetry: () => provider.loadProfile(widget.slug),
            );
          }

          final profile = provider.profile;
          if (profile == null) {
            return const _ErrorView(message: 'Business not found.');
          }

          return _ProfileContent(profile: profile, slug: widget.slug);
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final PublicBusinessProfile profile;
  final String slug;

  const _ProfileContent({required this.profile, required this.slug});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _ProfileAppBar(profile: profile, slug: slug),
        SliverToBoxAdapter(
          child: ResponsiveBuilder(
            builder: (context, size) {
              if (size == ScreenSize.desktop) {
                return _DesktopLayout(profile: profile, slug: slug);
              }
              return _MobileLayout(profile: profile, slug: slug);
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  final PublicBusinessProfile profile;
  final String slug;

  const _ProfileAppBar({required this.profile, required this.slug});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(RouteNames.publicSearch),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/b/$slug/book'),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Book Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Consumer<MediaProvider>(
          builder: (context, media, _) {
            final logoUrl =
                media.getBusinessLogo(profile.id)?.publicUrl ?? profile.logoUrl;
            final coverUrl =
                media.getBusinessCover(profile.id)?.publicUrl ??
                profile.coverImageUrl;
            return Stack(
              fit: StackFit.expand,
              children: [
                BusinessCoverWidget(coverUrl: coverUrl, height: 220),
                Container(color: Colors.black.withAlpha(77)),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      BusinessLogoWidget(
                        logoUrl: logoUrl,
                        size: 56,
                        businessName: profile.name,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (profile.categoryName != null)
                              Text(
                                profile.categoryName!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final PublicBusinessProfile profile;
  final String slug;

  const _DesktopLayout({required this.profile, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _AboutCard(profile: profile),
                const SizedBox(height: 16),
                _ServicesCard(profile: profile),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _BookNowCard(slug: slug),
                const SizedBox(height: 16),
                _BranchesCard(profile: profile),
                const SizedBox(height: 16),
                _ContactCard(profile: profile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final PublicBusinessProfile profile;
  final String slug;

  const _MobileLayout({required this.profile, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _BookNowCard(slug: slug),
          const SizedBox(height: 12),
          _AboutCard(profile: profile),
          const SizedBox(height: 12),
          _ServicesCard(profile: profile),
          const SizedBox(height: 12),
          _BranchesCard(profile: profile),
          const SizedBox(height: 12),
          _ContactCard(profile: profile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BookNowCard extends StatelessWidget {
  final String slug;

  const _BookNowCard({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Ready to book?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a service and time that works for you',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/b/$slug/book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Book an Appointment',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final PublicBusinessProfile profile;

  const _AboutCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.description != null && profile.description!.isNotEmpty)
            Text(
              profile.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (profile.city != null || profile.country != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  [
                    profile.city,
                    profile.country,
                  ].where((e) => e != null).join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServicesCard extends StatelessWidget {
  final PublicBusinessProfile profile;

  const _ServicesCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.services.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Services',
      child: Column(
        children: profile.services.map((s) => _ServiceRow(service: s)).toList(),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final PublicServiceInfo service;

  const _ServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Consumer<MediaProvider>(
            builder: (context, media, _) {
              final imageUrl = media.getServiceImage(service.id)?.publicUrl;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MediaImageWidget(
                  imageUrl: imageUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  fallback: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              );
            },
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
                if (service.description != null)
                  Text(
                    service.description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${service.durationMinutes} min',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              if (service.price > 0)
                Text(
                  '\$${service.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchesCard extends StatelessWidget {
  final PublicBusinessProfile profile;

  const _BranchesCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.branches.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Locations',
      child: Column(
        children: profile.branches
            .map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Consumer<MediaProvider>(
                      builder: (context, media, _) {
                        final coverUrl = media.getBranchCover(b.id)?.publicUrl;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: MediaImageWidget(
                            imageUrl: coverUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            fallback: const Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (b.city != null)
                            Text(
                              b.city!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final PublicBusinessProfile profile;

  const _ContactCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasContact =
        profile.phone != null ||
        profile.email != null ||
        profile.website != null;
    if (!hasContact) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Contact',
      child: Column(
        children: [
          if (profile.phone != null)
            _ContactRow(icon: Icons.phone_outlined, text: profile.phone!),
          if (profile.email != null)
            _ContactRow(icon: Icons.email_outlined, text: profile.email!),
          if (profile.website != null)
            _ContactRow(icon: Icons.language_outlined, text: profile.website!),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 64,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(RouteNames.publicSearch),
              child: const Text('Back to Search'),
            ),
          ],
        ),
      ),
    );
  }
}
