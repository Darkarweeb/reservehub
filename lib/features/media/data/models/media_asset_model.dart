import '../../../media/domain/entities/media_asset_entity.dart';

/// Data model for [MediaAssetEntity] — maps Supabase media_assets table.
class MediaAssetModel extends MediaAssetEntity {
  const MediaAssetModel({
    required super.id,
    super.organizationId,
    super.businessId,
    super.branchId,
    super.serviceId,
    required super.mediaType,
    required super.storageBucket,
    required super.storagePath,
    super.publicUrl,
    required super.mimeType,
    required super.fileSize,
    super.width,
    super.height,
    super.displayOrder,
    super.isActive,
    super.altText,
    super.caption,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MediaAssetModel.fromJson(Map<String, dynamic> json) {
    return MediaAssetModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      businessId: json['business_id'] as String?,
      branchId: json['branch_id'] as String?,
      serviceId: json['service_id'] as String?,
      mediaType: MediaAssetType.fromString(json['media_type'] as String),
      storageBucket: json['storage_bucket'] as String,
      storagePath: json['storage_path'] as String,
      publicUrl: json['public_url'] as String?,
      mimeType: json['mime_type'] as String,
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      altText: json['alt_text'] as String?,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'organization_id': organizationId,
    'business_id': businessId,
    'branch_id': branchId,
    'service_id': serviceId,
    'media_type': mediaType.value,
    'storage_bucket': storageBucket,
    'storage_path': storagePath,
    'public_url': publicUrl,
    'mime_type': mimeType,
    'file_size': fileSize,
    'width': width,
    'height': height,
    'display_order': displayOrder,
    'is_active': isActive,
    'alt_text': altText,
    'caption': caption,
  };
}
