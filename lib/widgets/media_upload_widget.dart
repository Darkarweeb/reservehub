import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../features/management/presentation/providers/management_provider.dart';
import '../features/media/domain/entities/media_asset_entity.dart';
import '../features/media/presentation/providers/media_provider.dart';
import '../theme/app_theme.dart';
import './media_image_widget.dart';

/// A compact, reusable image uploader for a single media asset.
/// Used for employee avatars, service images, branch covers, etc.
class SingleMediaUploadWidget extends StatelessWidget {
  final String? currentImageUrl;
  final String? currentAssetId;
  final MediaAssetType mediaType;
  final String label;
  final double previewSize;
  final double aspectRatio;
  final bool isCircular;
  final String? fallbackInitial;
  final String organizationId;
  final String businessId;
  final String? branchId;
  final String? serviceId;
  final String? employeeId;
  final VoidCallback? onUploaded;
  final VoidCallback? onDeleted;

  const SingleMediaUploadWidget({
    super.key,
    this.currentImageUrl,
    this.currentAssetId,
    required this.mediaType,
    required this.label,
    this.previewSize = 80,
    this.aspectRatio = 1.0,
    this.isCircular = false,
    this.fallbackInitial,
    required this.organizationId,
    required this.businessId,
    this.branchId,
    this.serviceId,
    this.employeeId,
    this.onUploaded,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, media, _) {
        return Row(
          children: [
            // Preview
            _buildPreview(context),
            const SizedBox(width: 12),
            // Actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (media.uploading) ...[
                    LinearProgressIndicator(
                      value: media.uploadProgress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.secondary,
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Uploading ${(media.uploadProgress * 100).toInt()}%...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Flexible(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickAndUpload(context, media),
                            icon: const Icon(Icons.upload_outlined, size: 14),
                            label: Text(
                              currentImageUrl != null ? 'Replace' : 'Upload',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondary,
                              side: const BorderSide(color: AppTheme.secondary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ),
                        if (currentAssetId != null) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _deleteAsset(context, media),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            color: AppTheme.error,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: 'Remove $label',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPEG, PNG or WebP · Max 5MB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreview(BuildContext context) {
    final size = previewSize;
    final br = isCircular
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(8);

    if (currentImageUrl != null) {
      return ClipRRect(
        borderRadius: br,
        child: MediaImageWidget(
          imageUrl: currentImageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: label,
        ),
      );
    }

    // Fallback
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: br,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: fallbackInitial != null
          ? Center(
              child: Text(
                fallbackInitial!.isNotEmpty
                    ? fallbackInitial![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            )
          : Center(
              child: Icon(
                _iconForType(),
                size: size * 0.35,
                color: const Color(0xFFCBD5E1),
              ),
            ),
    );
  }

  IconData _iconForType() {
    return switch (mediaType) {
      MediaAssetType.employeeAvatar => Icons.person_outline,
      MediaAssetType.serviceImage => Icons.spa_outlined,
      MediaAssetType.branchCover => Icons.place_outlined,
      MediaAssetType.branchGallery => Icons.photo_library_outlined,
      _ => Icons.image_outlined,
    };
  }

  Future<void> _pickAndUpload(BuildContext context, MediaProvider media) async {
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
      if (currentAssetId != null) {
        await media.deleteMedia(
          assetId: currentAssetId!,
          businessId: businessId,
          branchId: branchId,
          serviceId: serviceId,
          employeeId: employeeId,
        );
      }

      // Build alt text to embed employee id for lookup
      final altText = employeeId != null
          ? 'employee:$employeeId'
          : '$label image';

      final uploadResult = await media.uploadMedia(
        request: MediaUploadRequest(
          organizationId: organizationId,
          businessId: businessId,
          branchId: branchId,
          serviceId: serviceId,
          mediaType: mediaType,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          altText: altText,
        ),
      );

      if (context.mounted) {
        uploadResult.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label uploaded successfully'),
                backgroundColor: AppTheme.success,
              ),
            );
            onUploaded?.call();
          },
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

  Future<void> _deleteAsset(BuildContext context, MediaProvider media) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $label?'),
        content: Text('This will permanently remove the $label.'),
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
      assetId: currentAssetId!,
      businessId: businessId,
      branchId: branchId,
      serviceId: serviceId,
      employeeId: employeeId,
    );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label removed'),
              backgroundColor: AppTheme.success,
            ),
          );
          onDeleted?.call();
        },
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

/// Employee avatar widget with upload capability for the management dashboard.
class EmployeeAvatarUploadWidget extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final double size;

  const EmployeeAvatarUploadWidget({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.size = 56,
  });

  @override
  State<EmployeeAvatarUploadWidget> createState() =>
      _EmployeeAvatarUploadWidgetState();
}

class _EmployeeAvatarUploadWidgetState
    extends State<EmployeeAvatarUploadWidget> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_initialized) return;
    final mgmt = context.read<ManagementProvider>();
    final bizId = mgmt.businessId;
    if (bizId != null && mounted) {
      await context.read<MediaProvider>().loadEmployeeMedia(
        widget.employeeId,
        bizId,
      );
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagementProvider, MediaProvider>(
      builder: (context, mgmt, media, _) {
        final bizId = mgmt.businessId;
        final orgId = mgmt.organizationId;
        if (bizId == null || orgId == null) {
          return _AvatarFallback(name: widget.employeeName, size: widget.size);
        }

        final avatar = media.getEmployeeAvatar(widget.employeeId);
        final avatarUrl = avatar?.publicUrl;

        return GestureDetector(
          onTap: () =>
              _showAvatarOptions(context, media, bizId, orgId, avatar?.id),
          child: Stack(
            children: [
              _buildAvatar(avatarUrl),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? url) {
    if (url != null) {
      return ClipOval(
        child: MediaImageWidget(
          imageUrl: url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          semanticLabel: '${widget.employeeName} avatar',
        ),
      );
    }
    return _AvatarFallback(name: widget.employeeName, size: widget.size);
  }

  void _showAvatarOptions(
    BuildContext context,
    MediaProvider media,
    String bizId,
    String orgId,
    String? currentAssetId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: Text(
                currentAssetId != null ? 'Replace Photo' : 'Upload Photo',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(context, media, bizId, orgId, currentAssetId);
              },
            ),
            if (currentAssetId != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.error,
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAvatar(context, media, bizId, currentAssetId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    MediaProvider media,
    String bizId,
    String orgId,
    String? currentAssetId,
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

      if (currentAssetId != null) {
        await media.deleteMedia(
          assetId: currentAssetId,
          businessId: bizId,
          employeeId: widget.employeeId,
        );
      }

      final uploadResult = await media.uploadMedia(
        request: MediaUploadRequest(
          organizationId: orgId,
          businessId: bizId,
          mediaType: MediaAssetType.employeeAvatar,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          altText: 'employee:${widget.employeeId}',
        ),
      );

      if (context.mounted) {
        uploadResult.fold(
          onSuccess: (_) {
            // Reload employee media to update cache
            media.loadEmployeeMedia(widget.employeeId, bizId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avatar updated'),
                backgroundColor: AppTheme.success,
              ),
            );
          },
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

  Future<void> _deleteAvatar(
    BuildContext context,
    MediaProvider media,
    String bizId,
    String assetId,
  ) async {
    final result = await media.deleteMedia(
      assetId: assetId,
      businessId: bizId,
      employeeId: widget.employeeId,
    );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar removed'),
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

class _AvatarFallback extends StatelessWidget {
  final String name;
  final double size;

  const _AvatarFallback({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
