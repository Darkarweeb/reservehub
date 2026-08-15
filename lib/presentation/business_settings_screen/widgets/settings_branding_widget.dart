import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../features/management/presentation/providers/management_provider.dart';
import '../../../features/media/domain/entities/media_asset_entity.dart';
import '../../../features/media/presentation/providers/media_provider.dart';
import '../../../widgets/media_image_widget.dart';

/// Branding & Appearance section for Business Settings.
class SettingsBrandingWidget extends StatefulWidget {
  const SettingsBrandingWidget({super.key});

  @override
  State<SettingsBrandingWidget> createState() => _SettingsBrandingWidgetState();
}

class _SettingsBrandingWidgetState extends State<SettingsBrandingWidget> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_initialized) return;
    final mgmt = context.read<ManagementProvider>();
    if (mgmt.businessId == null) await mgmt.initialize();
    final bizId = mgmt.businessId;
    if (bizId != null && mounted) {
      await context.read<MediaProvider>().loadBusinessMedia(bizId);
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagementProvider, MediaProvider>(
      builder: (context, mgmt, media, _) {
        final bizId = mgmt.businessId;

        if (bizId == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Branding & Appearance',
                subtitle: 'Manage your business visual identity',
                icon: Icons.palette_outlined,
              ),
              const SizedBox(height: 24),
              _BrandingCard(
                title: 'Business Logo',
                subtitle: 'Displayed on your public profile and search results',
                child: _SingleImageUploader(
                  businessId: bizId,
                  mediaType: MediaAssetType.businessLogo,
                  label: 'Logo',
                  aspectRatio: 1.0,
                  previewSize: 120,
                ),
              ),
              const SizedBox(height: 16),
              _BrandingCard(
                title: 'Cover Image',
                subtitle: 'The banner shown at the top of your profile page',
                child: _SingleImageUploader(
                  businessId: bizId,
                  mediaType: MediaAssetType.businessCover,
                  label: 'Cover',
                  aspectRatio: 16 / 9,
                  previewSize: 200,
                ),
              ),
              const SizedBox(height: 16),
              _BrandingCard(
                title: 'Photo Gallery',
                subtitle: 'Showcase your business with up to 12 photos',
                child: _GalleryManager(businessId: bizId),
              ),
              if (media.uploadError != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(
                  message: media.uploadError!,
                  onDismiss: media.clearError,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Single Image Uploader ────────────────────────────────────────────────────

class _SingleImageUploader extends StatelessWidget {
  final String businessId;
  final MediaAssetType mediaType;
  final String label;
  final double aspectRatio;
  final double previewSize;

  const _SingleImageUploader({
    required this.businessId,
    required this.mediaType,
    required this.label,
    required this.aspectRatio,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagementProvider, MediaProvider>(
      builder: (context, mgmt, media, _) {
        final assets = media.getBusinessMedia(businessId, type: mediaType);
        final current = assets.where((a) => a.isActive).firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagePreviewBox(
              imageUrl: current?.publicUrl,
              width: aspectRatio >= 1.5 ? double.infinity : previewSize,
              height: aspectRatio >= 1.5
                  ? (previewSize * (1 / aspectRatio)).clamp(80.0, 200.0)
                  : previewSize,
              mediaType: mediaType,
            ),
            const SizedBox(height: 12),
            if (media.uploading) ...[
              UploadProgressWidget(progress: media.uploadProgress),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                FilledButton.icon(
                  onPressed: media.uploading
                      ? null
                      : () => _pickAndUpload(context, mgmt, media),
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: Text(
                    current != null ? 'Replace $label' : 'Upload $label',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                if (current != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteAsset(context, media, current.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'JPEG, PNG or WebP · Max 5MB',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    ManagementProvider mgmt,
    MediaProvider media,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final mimeType = _mimeFromExtension(file.extension ?? 'jpg');
      final validation = media.validateFile(
        mimeType: mimeType,
        fileName: file.name,
        fileSize: bytes.length,
      );
      if (!validation.isValid && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.errorMessage ?? 'Invalid file'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      // Delete existing if replacing
      final existing = media
          .getBusinessMedia(businessId, type: mediaType)
          .where((a) => a.isActive)
          .firstOrNull;
      if (existing != null) {
        await media.deleteMedia(assetId: existing.id, businessId: businessId);
      }

      final orgId = mgmt.organizationId;
      if (orgId == null) return;

      final uploadResult = await media.uploadMedia(
        request: MediaUploadRequest(
          organizationId: orgId,
          businessId: businessId,
          mediaType: mediaType,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          altText: 'Business $label',
        ),
      );

      if (context.mounted) {
        uploadResult.fold(
          onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label uploaded successfully'),
              backgroundColor: AppTheme.success,
            ),
          ),
          onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message ?? 'Upload failed'),
              backgroundColor: AppTheme.error,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAsset(
    BuildContext context,
    MediaProvider media,
    String assetId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $label?'),
        content: Text(
          'This will permanently remove the $label from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final result = await media.deleteMedia(
      assetId: assetId,
      businessId: businessId,
    );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label removed'),
            backgroundColor: AppTheme.success,
          ),
        ),
        onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message ?? 'Failed to remove'),
            backgroundColor: AppTheme.error,
          ),
        ),
      );
    }
  }

  String _mimeFromExtension(String ext) {
    return switch (ext.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

// ─── Gallery Manager ──────────────────────────────────────────────────────────

class _GalleryManager extends StatelessWidget {
  final String businessId;

  const _GalleryManager({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagementProvider, MediaProvider>(
      builder: (context, mgmt, media, _) {
        final gallery = media.getBusinessGallery(businessId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gallery.isNotEmpty) ...[
              _GalleryGrid(
                assets: gallery,
                businessId: businessId,
                onDelete: (id) => _deleteGalleryItem(context, media, id),
                onToggle: (id, active) => media.toggleActive(
                  assetId: id,
                  businessId: businessId,
                  isActive: active,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (media.uploading) ...[
              UploadProgressWidget(progress: media.uploadProgress),
              const SizedBox(height: 12),
            ],
            if (gallery.length < 12)
              FilledButton.icon(
                onPressed: media.uploading
                    ? null
                    : () => _pickGalleryImage(context, mgmt, media),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: Text(gallery.isEmpty ? 'Add Photos' : 'Add More Photos'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              )
            else
              Text(
                'Maximum 12 photos reached',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'JPEG, PNG or WebP · Max 5MB per photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickGalleryImage(
    BuildContext context,
    ManagementProvider mgmt,
    MediaProvider media,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final mimeType = _mimeFromExtension(file.extension ?? 'jpg');
      final validation = media.validateFile(
        mimeType: mimeType,
        fileName: file.name,
        fileSize: bytes.length,
      );

      if (!validation.isValid && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.errorMessage ?? 'Invalid file'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final orgId = mgmt.organizationId;
      if (orgId == null) return;

      final uploadResult = await media.uploadMedia(
        request: MediaUploadRequest(
          organizationId: orgId,
          businessId: businessId,
          mediaType: MediaAssetType.businessGallery,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
        ),
      );

      if (context.mounted) {
        uploadResult.fold(
          onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo added to gallery'),
              backgroundColor: AppTheme.success,
            ),
          ),
          onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message ?? 'Upload failed'),
              backgroundColor: AppTheme.error,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteGalleryItem(
    BuildContext context,
    MediaProvider media,
    String assetId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text('This photo will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    await media.deleteMedia(assetId: assetId, businessId: businessId);
  }

  String _mimeFromExtension(String ext) {
    return switch (ext.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

// ─── Gallery Grid ─────────────────────────────────────────────────────────────

class _GalleryGrid extends StatelessWidget {
  final List<MediaAssetEntity> assets;
  final String businessId;
  final void Function(String id) onDelete;
  final void Function(String id, bool active) onToggle;

  const _GalleryGrid({
    required this.assets,
    required this.businessId,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: assets.length,
      itemBuilder: (context, i) {
        final asset = assets[i];
        return _GalleryTile(
          asset: asset,
          onDelete: () => onDelete(asset.id),
          onToggle: (v) => onToggle(asset.id, v),
        );
      },
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final MediaAssetEntity asset;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  const _GalleryTile({
    required this.asset,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: MediaImageWidget(
            imageUrl: asset.publicUrl,
            fit: BoxFit.cover,
            semanticLabel: asset.altText ?? 'Gallery photo',
          ),
        ),
        if (!asset.isActive)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: Icon(Icons.visibility_off, color: Colors.white54),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TileButton(
                icon: asset.isActive
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onTap: () => onToggle(!asset.isActive),
                color: asset.isActive ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 2),
              _TileButton(
                icon: Icons.delete_outline,
                onTap: onDelete,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _TileButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─── Image Preview Box ────────────────────────────────────────────────────────

class _ImagePreviewBox extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final MediaAssetType mediaType;

  const _ImagePreviewBox({
    this.imageUrl,
    required this.width,
    required this.height,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: imageUrl != null
            ? MediaImageWidget(
                imageUrl: imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
              )
            : _EmptyPreview(mediaType: mediaType),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final MediaAssetType mediaType;

  const _EmptyPreview({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mediaType) {
      MediaAssetType.businessLogo => Icons.business_outlined,
      MediaAssetType.businessCover => Icons.panorama_outlined,
      _ => Icons.image_outlined,
    };
    final label = switch (mediaType) {
      MediaAssetType.businessLogo => 'No logo uploaded',
      MediaAssetType.businessCover => 'No cover image uploaded',
      _ => 'No image',
    };

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _BrandingCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.error,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            color: AppTheme.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}