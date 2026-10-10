import 'college_model.dart';
import 'post_model.dart';
import '../services/content_sanitizer.dart';

String _normalizeImageUrl(Map<String, dynamic> data, List<String> candidates) {
  for (final key in candidates) {
    final value = data[key];
    if (value != null) {
      final url = ContentSanitizer.sanitizeImageUrl(value);
      if (url.isNotEmpty) return url;
    }
  }
  return '';
}

List<String> _extractStringList(dynamic value) {
  if (value is List<dynamic>) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return [];
}

class University {
  final String id;
  final String name;
  final String description;
  final String city;
  final String type;
  final String websiteUrl;
  final String logoUrl;
  final String coverImageUrl;
  final List<College> colleges;
  final List<String> gallery;
  final List<Post> posts;
  final String managerEmail;
  final String whatsapp;

  University({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.type,
    required this.websiteUrl,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.colleges,
    required this.gallery,
    required this.posts,
    this.managerEmail = '',
    this.whatsapp = '',
  });

  factory University.fromMap(String id, Map<String, dynamic> data) {
    return University(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      whatsapp: (data['whatsapp'] ??
              data['whatsappNumber'] ??
              data['whatsappPhone'] ??
              data['phone'] ??
              '')
          .toString()
          .trim(),
      managerEmail: (data['managerEmail'] ?? data['adminEmail'] ?? '')
          .toString()
          .trim()
          .toLowerCase(),
      websiteUrl: ContentSanitizer.sanitizeLink(
        data['websiteUrl'] ?? data['website_url'] ?? '',
      ),
      logoUrl: _normalizeImageUrl(data, [
        'logoUrl',
        'logo_url',
        'logo',
        'imageUrl',
        'image',
        'image_url',
      ]),
      coverImageUrl: _normalizeImageUrl(data, [
        'coverImageUrl',
        'cover_image_url',
        'coverImage',
        'cover',
        'bannerUrl',
        'banner_url',
      ]),
      colleges: (data['colleges'] as List<dynamic>? ?? [])
          .map((c) => College.fromMap(c as Map<String, dynamic>))
          .toList(),
      gallery: _extractStringList(
        data['gallery'] ??
            data['images'] ??
            data['galleryUrls'] ??
            data['imageUrls'] ??
            [],
      )
          .map(ContentSanitizer.sanitizeImageUrl)
          .where((u) => u.isNotEmpty)
          .toList(),
      posts: (data['posts'] as List<dynamic>? ?? [])
          .map((p) => Post.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'city': city,
      'type': type,
      'websiteUrl': websiteUrl,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'colleges': colleges.map((c) => c.toMap()).toList(),
      'gallery': gallery,
      'posts': posts.map((p) => p.toMap()).toList(),
      'managerEmail': managerEmail.trim().toLowerCase(),
      'adminEmail': managerEmail.trim().toLowerCase(),
      'whatsapp': whatsapp.trim(),
    };
  }
}
