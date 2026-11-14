import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

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

  /// رفع صورة مباشر إلى Supabase Storage (حاوية images)
  Future<String> uploadImage({
    required String section,
    required String itemId,
    required String folder,
    required XFile file,
  }) async {
    final Uint8List bytes = await file.readAsBytes();
    final safeId = itemId.trim().isEmpty
        ? 'new_${DateTime.now().millisecondsSinceEpoch}'
        : itemId.trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$section/$safeId/$folder/img_$timestamp.jpg';

    final client = SupabaseService.client;
    await client.storage.from('images').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    final publicUrl = client.storage.from('images').getPublicUrl(path);
    debugPrint('✅ تم رفع الصورة بنجاح إلى Supabase Storage: $publicUrl');
    return publicUrl;
  }

  /// رفع صورة لجامعة
  Future<String> uploadUniversityImage({
    required String universityId,
    required XFile file,
    required String folder,
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
    required String folder,
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
    required String folder,
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
    required String folder,
  }) =>
      uploadImage(
        section: 'training_centers',
        itemId: centerId,
        folder: folder,
        file: file,
      );

  /// تحويل رسائل خطأ التخزين إلى رسائل واضحة ومفهومة للمستخدم
  static String getFriendlyErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('Bucket not found') || str.contains('NoSuchBucket')) {
      return 'حاوية التخزين "images" غير موجودة في Supabase Storage. يرجى الدخول إلى Supabase > Storage وإنشاء New bucket باسم images وتفعيل خيار Public bucket.';
    }
    if (str.contains('row-level security') ||
        str.contains('policy') ||
        str.contains('security policy')) {
      return 'تم رفض إذن الرفع في Supabase Storage. يرجى تفعيل صلاحية الرفع (Upload Policy) لحاوية images في لوحة Supabase Storage.';
    }
    if (str.contains('unauthorized') || str.contains('permission-denied')) {
      return 'تم رفض إذن الرفع. يرجى التحقق من أذونات التخزين في لوحة التحكم.';
    }
    if (str.contains('network') || str.contains('unavailable')) {
      return 'تعذر الاتصال بخادم التخزين، يرجى التحقق من اتصال الإنترنت.';
    }
    return 'فشل رفع الصورة: $e';
  }
}
