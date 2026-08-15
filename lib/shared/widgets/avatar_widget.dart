import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable avatar widget that shows a network image with a fallback
/// to initials when the image fails to load.
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final String? semanticLabel;

  const AvatarWidget({
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.semanticLabel,
    super.key,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticLabel ?? name,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildInitials(theme),
                )
              : _buildInitials(theme),
        ),
      ),
    );
  }

  Widget _buildInitials(ThemeData theme) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
