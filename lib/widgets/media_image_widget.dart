import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A polished image widget with loading, error, and fallback states.
///
/// Handles:
/// - Network image loading with shimmer skeleton
/// - Professional fallback when no URL provided
/// - Error state with branded placeholder
/// - Aspect ratio preservation
class MediaImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final String? semanticLabel;
  final Color? backgroundColor;

  const MediaImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.semanticLabel,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? const Color(0xFFF1F5F9);

    Widget content;

    if (imageUrl == null || imageUrl!.isEmpty) {
      content = fallback ?? _DefaultFallback(backgroundColor: effectiveBg);
    } else {
      content = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _LoadingSkeleton(
          width: width,
          height: height,
          backgroundColor: effectiveBg,
        ),
        errorWidget: (_, __, ___) =>
            fallback ?? _DefaultFallback(backgroundColor: effectiveBg),
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    if (semanticLabel != null) {
      content = Semantics(label: semanticLabel, image: true, child: content);
    }

    return content;
  }
}

/// Business logo widget with circular/rounded display.
class BusinessLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final String businessName;
  final BorderRadius? borderRadius;

  const BusinessLogoWidget({
    super.key,
    this.logoUrl,
    this.size = 56,
    required this.businessName,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(10);
    return MediaImageWidget(
      imageUrl: logoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: br,
      semanticLabel: '$businessName logo',
      fallback: _BusinessLogoFallback(
        businessName: businessName,
        size: size,
        borderRadius: br,
      ),
    );
  }
}

/// Business cover image widget with gradient overlay.
class BusinessCoverWidget extends StatelessWidget {
  final String? coverUrl;
  final double height;
  final Widget? overlay;

  const BusinessCoverWidget({
    super.key,
    this.coverUrl,
    this.height = 220,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaImageWidget(
            imageUrl: coverUrl,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            fallback: _CoverFallback(height: height),
          ),
          // Gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(153)],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

/// Gallery grid widget for displaying a list of images.
class MediaGalleryWidget extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double spacing;
  final double aspectRatio;
  final void Function(int index)? onTap;

  const MediaGalleryWidget({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.spacing = 4,
    this.aspectRatio = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(i) : null,
          child: MediaImageWidget(
            imageUrl: imageUrls[i],
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(6),
            semanticLabel: 'Gallery image ${i + 1}',
          ),
        );
      },
    );
  }
}

/// Upload progress indicator widget.
class UploadProgressWidget extends StatelessWidget {
  final double progress;
  final String? label;

  const UploadProgressWidget({super.key, required this.progress, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 6),
        Text(
          label ?? 'Uploading ${(progress * 100).toInt()}%...',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

// ─── Private fallback widgets ─────────────────────────────────────────────────

class _LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final Color backgroundColor;

  const _LoadingSkeleton({
    this.width,
    this.height,
    required this.backgroundColor,
  });

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor.withAlpha(
          (_animation.value * 255).toInt(),
        ),
      ),
    );
  }
}

class _DefaultFallback extends StatelessWidget {
  final Color backgroundColor;

  const _DefaultFallback({required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 32),
      ),
    );
  }
}

class _BusinessLogoFallback extends StatelessWidget {
  final String businessName;
  final double size;
  final BorderRadius borderRadius;

  const _BusinessLogoFallback({
    required this.businessName,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final initial = businessName.isNotEmpty
        ? businessName[0].toUpperCase()
        : 'B';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  final double height;

  const _CoverFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_outlined, color: Colors.white54, size: 48),
      ),
    );
  }
}
