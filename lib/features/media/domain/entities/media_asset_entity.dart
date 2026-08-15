/// Domain entity representing a media asset stored in Supabase Storage.
class MediaAssetEntity {
  final String id;
  final String? organizationId;
  final String? businessId;
  final String? branchId;
  final String? serviceId;
  final MediaAssetType mediaType;
  final String storageBucket;
  final String storagePath;
  final String? publicUrl;
  final String mimeType;
  final int fileSize;
  final int? width;
  final int? height;
  final int displayOrder;
  final bool isActive;
  final String? altText;
  final String? caption;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaAssetEntity({
    required this.id,
    this.organizationId,
    this.businessId,
    this.branchId,
    this.serviceId,
    required this.mediaType,
    required this.storageBucket,
    required this.storagePath,
    this.publicUrl,
    required this.mimeType,
    required this.fileSize,
    this.width,
    this.height,
    this.displayOrder = 0,
    this.isActive = true,
    this.altText,
    this.caption,
    required this.createdAt,
    required this.updatedAt,
  });

  MediaAssetEntity copyWith({
    String? publicUrl,
    int? displayOrder,
    bool? isActive,
    String? altText,
    String? caption,
  }) {
    return MediaAssetEntity(
      id: id,
      organizationId: organizationId,
      businessId: businessId,
      branchId: branchId,
      serviceId: serviceId,
      mediaType: mediaType,
      storageBucket: storageBucket,
      storagePath: storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      mimeType: mimeType,
      fileSize: fileSize,
      width: width,
      height: height,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      altText: altText ?? this.altText,
      caption: caption ?? this.caption,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MediaAssetEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MediaAssetEntity(id: $id, type: $mediaType, path: $storagePath)';
}

/// Enum representing the type of media asset.
enum MediaAssetType {
  businessLogo('business_logo'),
  businessCover('business_cover'),
  businessGallery('business_gallery'),
  branchCover('branch_cover'),
  branchGallery('branch_gallery'),
  serviceImage('service_image'),
  platformAsset('platform_asset'),
  employeeAvatar('employee_avatar');

  final String value;
  const MediaAssetType(this.value);

  static MediaAssetType fromString(String value) {
    return MediaAssetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MediaAssetType.businessGallery,
    );
  }
}

/// Upload request parameters.
class MediaUploadRequest {
  final String organizationId;
  final String? businessId;
  final String? branchId;
  final String? serviceId;
  final MediaAssetType mediaType;
  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final String? altText;
  final String? caption;

  const MediaUploadRequest({
    required this.organizationId,
    this.businessId,
    this.branchId,
    this.serviceId,
    required this.mediaType,
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.altText,
    this.caption,
  });
}

/// Validation result for file uploads.
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  const FileValidationResult({required this.isValid, this.errorMessage});

  factory FileValidationResult.valid() =>
      const FileValidationResult(isValid: true);

  factory FileValidationResult.invalid(String message) =>
      FileValidationResult(isValid: false, errorMessage: message);
}
