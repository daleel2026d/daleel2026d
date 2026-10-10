import 'college_model.dart';
import 'post_model.dart';
import '../services/content_sanitizer.dart';

class TrainingCenter {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String coverImageUrl;
  final String location;
  final String phone;
  final String email;
  final String website;
  final String facebook;
  final String instagram;
  final List<String> specialties;
  final List<College> colleges;
  final List<Post> posts;
  final List<String> gallery;

  TrainingCenter({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.coverImageUrl = '',
    required this.location,
    required this.phone,
    required this.email,
    required this.website,
    required this.facebook,
    required this.instagram,
    required this.specialties,
    this.colleges = const [],
    this.posts = const [],
    this.gallery = const [],
  });

  static List<String> _extractStringList(dynamic list) {
    if (list is List) {
      return list
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  factory TrainingCenter.fromMap(String id, Map<String, dynamic> data) {
    final imageUrl = ContentSanitizer.sanitizeImageUrl(
      data['imageUrl'] ??
          data['logoUrl'] ??
          data['image'] ??
          data['logo'] ??
          '',
    );

    final coverImageUrl = ContentSanitizer.sanitizeImageUrl(
      data['coverImageUrl'] ?? data['cover_image_url'] ?? data['cover'] ?? '',
    );

    List<String> specialtiesList = [];
    if (data['specialties'] is List) {
      specialtiesList = List<String>.from(data['specialties']);
    } else if (data['specialties'] is String &&
        (data['specialties'] as String).isNotEmpty) {
      specialtiesList = (data['specialties'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else if (data['services'] is List) {
      specialtiesList = List<String>.from(data['services']);
    }

    final rawColleges = data['colleges'] ?? data['courses'] ?? data['departments'] ?? [];
    final collegesList = (rawColleges is List)
        ? rawColleges
            .map((c) => c is Map<String, dynamic>
                ? College.fromMap(c)
                : College(name: c.toString(), minGpa: 0, category: 'دورة تدريبية'))
            .toList()
        : <College>[];

    final rawPosts = data['posts'] ?? [];
    final postsList = (rawPosts is List)
        ? rawPosts
            .map((p) => p is Map<String, dynamic>
                ? Post.fromMap(p)
                : Post(
                    title: p.toString(),
                    description: '',
                    date: '',
                  ))
            .toList()
        : <Post>[];

    return TrainingCenter(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ??
          data['about']?.toString() ??
          '',
      imageUrl: imageUrl,
      coverImageUrl: coverImageUrl,
      location: data['location']?.toString() ??
          data['city']?.toString() ??
          data['address']?.toString() ??
          '',
      phone: data['phone']?.toString() ?? data['contact']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      website: ContentSanitizer.sanitizeLink(
        data['website'] ?? data['link'] ?? '',
      ),
      facebook: ContentSanitizer.sanitizeLink(data['facebook'] ?? ''),
      instagram: ContentSanitizer.sanitizeLink(data['instagram'] ?? ''),
      specialties: specialtiesList,
      colleges: collegesList,
      posts: postsList,
      gallery: _extractStringList(
        data['gallery'] ?? data['images'] ?? data['imageUrls'] ?? [],
      )
          .map(ContentSanitizer.sanitizeImageUrl)
          .where((u) => u.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'coverImageUrl': coverImageUrl,
      'location': location,
      'phone': phone,
      'email': email,
      'website': website,
      'facebook': facebook,
      'instagram': instagram,
      'specialties': specialties,
      'colleges': colleges.map((c) => c.toMap()).toList(),
      'posts': posts.map((p) => p.toMap()).toList(),
      'gallery': gallery,
    };
  }
}
