import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/media_asset_entity.dart';
import '../../domain/repositories/media_repository.dart';

/// State management for media assets.
class MediaProvider extends ChangeNotifier {
  final MediaRepository _repository;

  MediaProvider({required MediaRepository repository})
    : _repository = repository;

  // ─── State ────────────────────────────────────────────────────────────────
  final Map<String, List<MediaAssetEntity>> _businessMedia = {};
  final Map<String, List<MediaAssetEntity>> _branchMedia = {};
  final Map<String, List<MediaAssetEntity>> _serviceMedia = {};
  final Map<String, List<MediaAssetEntity>> _employeeMedia = {};

  bool _loading = false;
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _error;
  String? _uploadError;

  bool get loading => _loading;
  bool get uploading => _uploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String? get uploadError => _uploadError;

  // ─── Business Getters ──────────────────────────────────────────────────────

  List<MediaAssetEntity> getBusinessMedia(
    String businessId, {
    MediaAssetType? type,
  }) {
    final all = _businessMedia[businessId] ?? [];
    if (type == null) return all;
    return all.where((a) => a.mediaType == type).toList();
  }

  MediaAssetEntity? getBusinessLogo(String businessId) {
    return getBusinessMedia(
      businessId,
      type: MediaAssetType.businessLogo,
    ).where((a) => a.isActive).firstOrNull;
  }

  MediaAssetEntity? getBusinessCover(String businessId) {
    return getBusinessMedia(
      businessId,
      type: MediaAssetType.businessCover,
    ).where((a) => a.isActive).firstOrNull;
  }

  List<MediaAssetEntity> getBusinessGallery(String businessId) {
    return getBusinessMedia(
      businessId,
      type: MediaAssetType.businessGallery,
    ).where((a) => a.isActive).toList();
  }

  // ─── Branch Getters ────────────────────────────────────────────────────────

  List<MediaAssetEntity> getBranchMedia(String branchId) {
    return _branchMedia[branchId] ?? [];
  }

  MediaAssetEntity? getBranchCover(String branchId) {
    return getBranchMedia(branchId)
        .where((a) => a.mediaType == MediaAssetType.branchCover && a.isActive)
        .firstOrNull;
  }

  List<MediaAssetEntity> getBranchGallery(String branchId) {
    return getBranchMedia(branchId)
        .where((a) => a.mediaType == MediaAssetType.branchGallery && a.isActive)
        .toList();
  }

  // ─── Service Getters ───────────────────────────────────────────────────────

  List<MediaAssetEntity> getServiceMedia(String serviceId) {
    return _serviceMedia[serviceId] ?? [];
  }

  MediaAssetEntity? getServiceImage(String serviceId) {
    return getServiceMedia(serviceId)
        .where((a) => a.mediaType == MediaAssetType.serviceImage && a.isActive)
        .firstOrNull;
  }

  // ─── Employee Getters ──────────────────────────────────────────────────────

  List<MediaAssetEntity> getEmployeeMedia(String employeeId) {
    return _employeeMedia[employeeId] ?? [];
  }

  MediaAssetEntity? getEmployeeAvatar(String employeeId) {
    return getEmployeeMedia(employeeId)
        .where(
          (a) => a.mediaType == MediaAssetType.employeeAvatar && a.isActive,
        )
        .firstOrNull;
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadBusinessMedia(String businessId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getBusinessMedia(businessId: businessId);
    result.fold(
      onSuccess: (assets) {
        _businessMedia[businessId] = assets;
        _loading = false;
      },
      onFailure: (f) {
        _error = f.message ?? 'Failed to load media';
        _loading = false;
      },
    );
    notifyListeners();
  }

  Future<void> loadBranchMedia(String branchId) async {
    final result = await _repository.getBranchMedia(branchId: branchId);
    result.fold(
      onSuccess: (assets) => _branchMedia[branchId] = assets,
      onFailure: (_) {},
    );
    notifyListeners();
  }

  Future<void> loadServiceMedia(String serviceId) async {
    final result = await _repository.getServiceMedia(serviceId: serviceId);
    result.fold(
      onSuccess: (assets) => _serviceMedia[serviceId] = assets,
      onFailure: (_) {},
    );
    notifyListeners();
  }

  /// Loads employee avatar from business media cache (filtered by employeeId).
  /// Employee avatars are stored in business-media bucket but with an
  /// employee_id reference. We query via getBusinessMedia with employeeAvatar type
  /// and filter client-side, or load directly via a dedicated query.
  Future<void> loadEmployeeMedia(String employeeId, String businessId) async {
    // Query business media filtered to employee avatar type, then filter by employeeId
    final result = await _repository.getBusinessMedia(
      businessId: businessId,
      mediaType: MediaAssetType.employeeAvatar,
    );
    result.fold(
      onSuccess: (assets) {
        // Filter to this specific employee
        _employeeMedia[employeeId] = assets
            .where((a) => a.storagePath.contains(employeeId))
            .toList();
      },
      onFailure: (_) {},
    );
    notifyListeners();
  }

  // ─── Upload ───────────────────────────────────────────────────────────────

  Future<Result<MediaAssetEntity>> uploadMedia({
    required MediaUploadRequest request,
  }) async {
    _uploading = true;
    _uploadProgress = 0.0;
    _uploadError = null;
    notifyListeners();

    final result = await _repository.uploadMedia(
      request: request,
      onProgress: (p) {
        _uploadProgress = p;
        notifyListeners();
      },
    );

    result.fold(
      onSuccess: (asset) {
        // Add to appropriate local cache
        if (request.businessId != null) {
          final list = List<MediaAssetEntity>.from(
            _businessMedia[request.businessId!] ?? [],
          );
          list.add(asset);
          list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          _businessMedia[request.businessId!] = list;
        }
        if (request.branchId != null) {
          final list = List<MediaAssetEntity>.from(
            _branchMedia[request.branchId!] ?? [],
          );
          list.add(asset);
          _branchMedia[request.branchId!] = list;
        }
        if (request.serviceId != null) {
          final list = List<MediaAssetEntity>.from(
            _serviceMedia[request.serviceId!] ?? [],
          );
          list.add(asset);
          _serviceMedia[request.serviceId!] = list;
        }
        // Employee avatars: update employee cache via storage path
        if (request.mediaType == MediaAssetType.employeeAvatar) {
          // Find employee id from the storage path (orgId/bizId/employee_avatar/empId_...)
          // We store it in business cache above; also update employee cache if we can
          // identify the employee from the path
          final pathParts = asset.storagePath.split('/');
          if (pathParts.length >= 4) {
            // path: orgId/bizId/employee_avatar/timestamp_empId_filename
            final fileName = pathParts.last;
            // We embed employeeId in altText for reliable lookup
            if (request.altText != null) {
              final empId = request.altText!.replaceFirst('employee:', '');
              if (empId.isNotEmpty &&
                  request.altText!.startsWith('employee:')) {
                final empList = List<MediaAssetEntity>.from(
                  _employeeMedia[empId] ?? [],
                );
                empList.add(asset);
                _employeeMedia[empId] = empList;
              }
            }
          }
        }
        _uploading = false;
        _uploadProgress = 1.0;
      },
      onFailure: (f) {
        _uploadError = f.message ?? 'Upload failed';
        _uploading = false;
      },
    );
    notifyListeners();
    return result;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<Result<void>> deleteMedia({
    required String assetId,
    String? businessId,
    String? branchId,
    String? serviceId,
    String? employeeId,
  }) async {
    final result = await _repository.deleteMedia(assetId: assetId);
    result.fold(
      onSuccess: (_) {
        if (businessId != null) {
          final list = List<MediaAssetEntity>.from(
            _businessMedia[businessId] ?? [],
          );
          list.removeWhere((a) => a.id == assetId);
          _businessMedia[businessId] = list;
        }
        if (branchId != null) {
          final list = List<MediaAssetEntity>.from(
            _branchMedia[branchId] ?? [],
          );
          list.removeWhere((a) => a.id == assetId);
          _branchMedia[branchId] = list;
        }
        if (serviceId != null) {
          final list = List<MediaAssetEntity>.from(
            _serviceMedia[serviceId] ?? [],
          );
          list.removeWhere((a) => a.id == assetId);
          _serviceMedia[serviceId] = list;
        }
        if (employeeId != null) {
          final list = List<MediaAssetEntity>.from(
            _employeeMedia[employeeId] ?? [],
          );
          list.removeWhere((a) => a.id == assetId);
          _employeeMedia[employeeId] = list;
        }
      },
      onFailure: (_) {},
    );
    notifyListeners();
    return result;
  }

  // ─── Reorder ──────────────────────────────────────────────────────────────

  Future<void> reorderGallery({
    required String businessId,
    required List<String> orderedIds,
  }) async {
    // Optimistic update
    final current = List<MediaAssetEntity>.from(
      _businessMedia[businessId] ?? [],
    );
    final gallery = current
        .where((a) => a.mediaType == MediaAssetType.businessGallery)
        .toList();
    final reordered = <MediaAssetEntity>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final asset = gallery.firstWhere(
        (a) => a.id == orderedIds[i],
        orElse: () => gallery[i],
      );
      reordered.add(asset.copyWith(displayOrder: i));
    }
    final nonGallery = current
        .where((a) => a.mediaType != MediaAssetType.businessGallery)
        .toList();
    _businessMedia[businessId] = [...nonGallery, ...reordered];
    notifyListeners();

    await _repository.reorderMedia(orderedIds: orderedIds);
  }

  // ─── Toggle ───────────────────────────────────────────────────────────────

  Future<void> toggleActive({
    required String assetId,
    required String businessId,
    required bool isActive,
  }) async {
    final list = List<MediaAssetEntity>.from(_businessMedia[businessId] ?? []);
    final idx = list.indexWhere((a) => a.id == assetId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isActive: isActive);
      _businessMedia[businessId] = list;
      notifyListeners();
    }
    await _repository.toggleMediaActive(assetId: assetId, isActive: isActive);
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  FileValidationResult validateFile({
    required String mimeType,
    required String fileName,
    required int fileSize,
  }) {
    return _repository.validateFile(
      mimeType: mimeType,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  void clearError() {
    _error = null;
    _uploadError = null;
    notifyListeners();
  }
}
