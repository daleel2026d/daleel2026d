import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_model.dart';
import 'post_model.dart';
import '../services/content_sanitizer.dart';

class Scholarship {
  final String id;
  final String name;
  final String country;
  final String fundingType;
  final String deadline;
  final String imageUrl;
  final String coverImageUrl;
  final String description;
  final String officialLink;
  final List<College> colleges;
  final List<Post> posts;
  final List<String> gallery;

  Scholarship({
    required this.id,
    required this.name,
    required this.country,
    required this.fundingType,
    required this.deadline,
    required this.imageUrl,
    this.coverImageUrl = '',
    required this.description,
    required this.officialLink,
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

  factory Scholarship.fromMap(String id, Map<String, dynamic> data) {
    String deadlineStr = '';
    final rawDeadline = data['deadline'];
    if (rawDeadline != null) {
      if (rawDeadline is Timestamp) {
        final dateTime = rawDeadline.toDate();
        deadlineStr =
            "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
      } else {
        deadlineStr = rawDeadline.toString();
      }
    }

    final imageUrl = ContentSanitizer.sanitizeImageUrl(
      data['imageUrl'] ?? data['image'] ?? data['image_url'] ?? data['logoUrl'] ?? '',
    );
    final coverImageUrl = ContentSanitizer.sanitizeImageUrl(
      data['coverImageUrl'] ?? data['cover_image_url'] ?? data['cover'] ?? '',
    );
    final officialLink = ContentSanitizer.sanitizeLink(
      data['officialLink'] ?? data['link'] ?? data['url'] ?? '',
    );

    final rawColleges = data['colleges'] ?? data['departments'] ?? data['majors'] ?? [];
    final collegesList = (rawColleges is List)
        ? rawColleges
            .map((c) => c is Map<String, dynamic>
                ? College.fromMap(c)
                : College(name: c.toString(), minGpa: 0, category: 'عام'))
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

    return Scholarship(
      id: id,
      name: data['name']?.toString() ?? '',
      country: data['country']?.toString() ?? '',
      fundingType: data['fundingType']?.toString() ?? '',
      deadline: deadlineStr,
      imageUrl: imageUrl,
      coverImageUrl: coverImageUrl,
      description: data['description']?.toString() ?? '',
      officialLink: officialLink,
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
      'country': country,
      'fundingType': fundingType,
      'deadline': deadline,
      'imageUrl': imageUrl,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'officialLink': officialLink,
      'colleges': colleges.map((c) => c.toMap()).toList(),
      'posts': posts.map((p) => p.toMap()).toList(),
      'gallery': gallery,
    };
  }
}
