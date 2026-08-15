import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:typed_data';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/media_asset_entity.dart';
import '../../domain/repositories/media_repository.dart';
import '../models/media_asset_model.dart';

/// Supabase-backed implementation of [MediaRepository].
class MediaRepositoryImpl implements MediaRepository {
  final SupabaseClient _client;

  static const _businessMediaBucket = 'business-media';
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const _allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  const MediaRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<List<MediaAssetEntity>>> getBusinessMedia({
    required String businessId,
    MediaAssetType? mediaType,
  }) async {
    try {
      var query = _client
          .from('media_assets')
          .select()
          .eq('business_id', businessId);

      if (mediaType != null) {
        query = query.eq('media_type', mediaType.value);
      }

      final rows = await query
          .order('display_order', ascending: true)
          .order('created_at', ascending: true);
      final assets = (rows as List<dynamic>)
          .map((r) => MediaAssetModel.fromJson(r as Map<String, dynamic>))
          .toList();
      return success(assets);
    } catch (e, st) {
      AppLogger.error('getBusinessMedia failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<List<MediaAssetEntity>>> getBranchMedia({
    required String branchId,
  }) async {
    try {
      final rows = await _client
          .from('media_assets')
          .select()
          .eq('branch_id', branchId)
          .order('display_order', ascending: true)
          .order('created_at', ascending: true);

      final assets = (rows as List<dynamic>)
          .map((r) => MediaAssetModel.fromJson(r as Map<String, dynamic>))
          .toList();
      return success(assets);
    } catch (e, st) {
      AppLogger.error('getBranchMedia failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<List<MediaAssetEntity>>> getServiceMedia({
    required String serviceId,
  }) async {
    try {
      final rows = await _client
          .from('media_assets')
          .select()
          .eq('service_id', serviceId)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final assets = (rows as List<dynamic>)
          .map((r) => MediaAssetModel.fromJson(r as Map<String, dynamic>))
          .toList();
      return success(assets);
    } catch (e, st) {
      AppLogger.error('getServiceMedia failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<MediaAssetEntity>> uploadMedia({
    required MediaUploadRequest request,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file
      final validation = validateFile(
        mimeType: request.mimeType,
        fileName: request.fileName,
        fileSize: request.bytes.length,
      );
      if (!validation.isValid) {
        return failure(
          ValidationFailure(message: validation.errorMessage ?? 'Invalid file'),
        );
      }

      // Build storage path: orgId/businessId/mediaType/timestamp_filename
      final ext = _extensionFromMime(request.mimeType);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName =
          '${timestamp}_${_sanitizeFileName(request.fileName)}';
      final pathParts = <String>[request.organizationId];
      if (request.businessId != null) pathParts.add(request.businessId!);
      pathParts.add(request.mediaType.value);
      pathParts.add(safeFileName);
      final storagePath = pathParts.join('/');

      // Upload to Supabase Storage
      await _client.storage
          .from(_businessMediaBucket)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(request.bytes),
            fileOptions: FileOptions(
              contentType: request.mimeType,
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(_businessMediaBucket)
          .getPublicUrl(storagePath);

      // Get next display order
      int nextOrder = 0;
      try {
        final existing = await _client
            .from('media_assets')
            .select('display_order')
            .eq('business_id', request.businessId ?? '')
            .eq('media_type', request.mediaType.value)
            .order('display_order', ascending: false)
            .limit(1);
        if ((existing as List).isNotEmpty) {
          nextOrder =
              ((existing.first['display_order'] as num?)?.toInt() ?? 0) + 1;
        }
      } catch (_) {}

      // Insert metadata
      final insertData = {
        'organization_id': request.organizationId,
        'business_id': request.businessId,
        'branch_id': request.branchId,
        'service_id': request.serviceId,
        'media_type': request.mediaType.value,
        'storage_bucket': _businessMediaBucket,
        'storage_path': storagePath,
        'public_url': publicUrl,
        'mime_type': request.mimeType,
        'file_size': request.bytes.length,
        'display_order': nextOrder,
        'is_active': true,
        'alt_text': request.altText,
        'caption': request.caption,
      };

      final row = await _client
          .from('media_assets')
          .insert(insertData)
          .select()
          .single();

      final asset = MediaAssetModel.fromJson(row);
      return success(asset);
    } catch (e, st) {
      AppLogger.error('uploadMedia failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> deleteMedia({required String assetId}) async {
    try {
      // Get the asset first to find storage path
      final row = await _client
          .from('media_assets')
          .select('storage_path, storage_bucket')
          .eq('id', assetId)
          .maybeSingle();

      if (row != null) {
        final path = row['storage_path'] as String;
        final bucket = row['storage_bucket'] as String;
        // Delete from storage
        try {
          await _client.storage.from(bucket).remove([path]);
        } catch (storageErr) {
          AppLogger.warning(
            'Storage delete failed for $path: $storageErr',
            tag: 'MediaRepo',
          );
        }
      }

      // Delete metadata
      await _client.from('media_assets').delete().eq('id', assetId);
      return success(null);
    } catch (e, st) {
      AppLogger.error('deleteMedia failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> reorderMedia({required List<String> orderedIds}) async {
    try {
      for (int i = 0; i < orderedIds.length; i++) {
        await _client
            .from('media_assets')
            .update({'display_order': i})
            .eq('id', orderedIds[i]);
      }
      return success(null);
    } catch (e, st) {
      AppLogger.error('reorderMedia failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> toggleMediaActive({
    required String assetId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('media_assets')
          .update({'is_active': isActive})
          .eq('id', assetId);
      return success(null);
    } catch (e, st) {
      AppLogger.error('toggleMediaActive failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> updateMediaMetadata({
    required String assetId,
    String? altText,
    String? caption,
  }) async {
    try {
      await _client
          .from('media_assets')
          .update({
            if (altText != null) 'alt_text': altText,
            if (caption != null) 'caption': caption,
          })
          .eq('id', assetId);
      return success(null);
    } catch (e, st) {
      AppLogger.error('updateMediaMetadata failed', tag: 'MediaRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  FileValidationResult validateFile({
    required String mimeType,
    required String fileName,
    required int fileSize,
  }) {
    // Check file size
    if (fileSize > _maxFileSizeBytes) {
      final sizeMb = (_maxFileSizeBytes / 1024 / 1024).toStringAsFixed(0);
      return FileValidationResult.invalid(
        'File is too large. Maximum size is ${sizeMb}MB.',
      );
    }

    // Check MIME type
    final normalizedMime = mimeType.toLowerCase().trim();
    if (!_allowedMimeTypes.contains(normalizedMime)) {
      return FileValidationResult.invalid(
        'Unsupported file type. Please use JPEG, PNG, or WebP.',
      );
    }

    // Check extension
    final ext = fileName.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      return FileValidationResult.invalid(
        'Unsupported file extension. Allowed: ${_allowedExtensions.join(', ')}',
      );
    }

    return FileValidationResult.valid();
  }

  @override
  String getPublicUrl({required String bucket, required String storagePath}) {
    return _client.storage.from(bucket).getPublicUrl(storagePath);
  }

  @override
  void dispose() {}

  // ─── Private helpers ───────────────────────────────────────────────────────

  String _extensionFromMime(String mime) {
    return switch (mime.toLowerCase()) {
      'image/jpeg' || 'image/jpg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_').toLowerCase();
  }
}
