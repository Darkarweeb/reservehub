import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/media_asset_entity.dart';

/// Contract for media asset operations.
abstract interface class MediaRepository implements BaseRepository {
  /// Fetches all media assets for a business, optionally filtered by type.
  Future<Result<List<MediaAssetEntity>>> getBusinessMedia({
    required String businessId,
    MediaAssetType? mediaType,
  });

  /// Fetches all media assets for a branch.
  Future<Result<List<MediaAssetEntity>>> getBranchMedia({
    required String branchId,
  });

  /// Fetches media assets for a service.
  Future<Result<List<MediaAssetEntity>>> getServiceMedia({
    required String serviceId,
  });

  /// Uploads a new media asset and stores metadata.
  Future<Result<MediaAssetEntity>> uploadMedia({
    required MediaUploadRequest request,
    void Function(double progress)? onProgress,
  });

  /// Deletes a media asset (storage + metadata).
  Future<Result<void>> deleteMedia({required String assetId});

  /// Updates display order for gallery items.
  Future<Result<void>> reorderMedia({required List<String> orderedIds});

  /// Toggles the is_active flag on a media asset.
  Future<Result<void>> toggleMediaActive({
    required String assetId,
    required bool isActive,
  });

  /// Updates alt text and caption.
  Future<Result<void>> updateMediaMetadata({
    required String assetId,
    String? altText,
    String? caption,
  });

  /// Validates a file before upload.
  FileValidationResult validateFile({
    required String mimeType,
    required String fileName,
    required int fileSize,
  });

  /// Generates a public URL for a storage path.
  String getPublicUrl({required String bucket, required String storagePath});
}
