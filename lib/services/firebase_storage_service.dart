import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// اختيار صورة من المعرض أو الكاميرا
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// رفع صورة عام في مجلد مخصص في Firebase Storage
  Future<String> uploadImage({
    required String section, // 'universities', 'scholarships', 'opportunities', 'training_centers'
    required String itemId,
    required String folder, // 'covers', 'logos', 'images', 'gallery', 'posts'
    required XFile file,
  }) async {
    final Uint8List bytes = await file.readAsBytes();
    final safeId = itemId.trim().isEmpty
        ? 'new_${DateTime.now().millisecondsSinceEpoch}'
        : itemId.trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$section/$safeId/$folder/img_$timestamp.jpg';

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'section': section,
        'itemId': safeId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = await ref.putData(bytes, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// رفع صورة لجامعة
  Future<String> uploadUniversityImage({
    required String universityId,
    required XFile file,
    required String folder, // 'covers', 'logos', 'gallery', 'posts'
  }) =>
      uploadImage(
        section: 'universities',
        itemId: universityId,
        folder: folder,
        file: file,
      );

  /// رفع صورة لمنحة دراسية
  Future<String> uploadScholarshipImage({
    required String scholarshipId,
    required XFile file,
    required String folder, // 'covers', 'logos', 'gallery', 'posts'
  }) =>
      uploadImage(
        section: 'scholarships',
        itemId: scholarshipId,
        folder: folder,
        file: file,
      );

  /// رفع صورة لفرصة أو فعالية
  Future<String> uploadOpportunityImage({
    required String opportunityId,
    required XFile file,
    required String folder, // 'covers', 'logos', 'gallery', 'posts'
  }) =>
      uploadImage(
        section: 'opportunities',
        itemId: opportunityId,
        folder: folder,
        file: file,
      );

  /// رفع صورة لمركز تدريب
  Future<String> uploadTrainingCenterImage({
    required String centerId,
    required XFile file,
    required String folder, // 'covers', 'logos', 'gallery', 'posts'
  }) =>
      uploadImage(
        section: 'training_centers',
        itemId: centerId,
        folder: folder,
        file: file,
      );
}
