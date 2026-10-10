import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_model.dart';
import 'post_model.dart';
import '../services/content_sanitizer.dart';

class Opportunity {
  final String id;
  final String title;
  final String description;
  final String organizer;
  final String type;
  final String attendance;
  final String targetAudience;
  final String date;
  final String registrationDeadline;
  final String price;
  final String registrationLink;
  final String imageUrl;
  final String coverImageUrl;
  final String location;
  final List<College> colleges;
  final List<Post> posts;
  final List<String> gallery;

  Opportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.organizer,
    required this.type,
    required this.attendance,
    required this.targetAudience,
    required this.date,
    required this.registrationDeadline,
    required this.price,
    required this.registrationLink,
    required this.imageUrl,
    this.coverImageUrl = '',
    required this.location,
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

  factory Opportunity.fromMap(String id, Map<String, dynamic> data) {
    final imageUrl = ContentSanitizer.sanitizeImageUrl(
      data['imageUrl'] ?? data['image'] ?? data['image_url'] ?? data['logoUrl'] ?? '',
    );
    final coverImageUrl = ContentSanitizer.sanitizeImageUrl(
      data['coverImageUrl'] ?? data['cover_image_url'] ?? data['cover'] ?? '',
    );
    final registrationLink = ContentSanitizer.sanitizeLink(
      data['registrationLink'] ?? data['link'] ?? data['url'] ?? '',
    );

    String date = '';
    final rawDate = data['date'];
    if (rawDate != null) {
      date = rawDate is Timestamp
          ? rawDate.toDate().toIso8601String()
          : rawDate.toString();
    }

    String registrationDeadline = '';
    final rawDeadline = data['registrationDeadline'];
    if (rawDeadline != null) {
      registrationDeadline = rawDeadline is Timestamp
          ? rawDeadline.toDate().toIso8601String()
          : rawDeadline.toString();
    }

    final rawColleges = data['colleges'] ?? data['departments'] ?? data['topics'] ?? [];
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

    return Opportunity(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      organizer: data['organizer']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      attendance: data['attendance']?.toString() ?? '',
      targetAudience: data['targetAudience']?.toString() ?? '',
      date: date,
      registrationDeadline: registrationDeadline,
      price: data['price']?.toString() ?? 'مجاني',
      registrationLink: registrationLink,
      imageUrl: imageUrl,
      coverImageUrl: coverImageUrl,
      location: data['location']?.toString() ?? '',
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
      'title': title,
      'description': description,
      'organizer': organizer,
      'type': type,
      'attendance': attendance,
      'targetAudience': targetAudience,
      'date': date,
      'registrationDeadline': registrationDeadline,
      'price': price,
      'registrationLink': registrationLink,
      'imageUrl': imageUrl,
      'coverImageUrl': coverImageUrl,
      'location': location,
      'colleges': colleges.map((c) => c.toMap()).toList(),
      'posts': posts.map((p) => p.toMap()).toList(),
      'gallery': gallery,
    };
  }
}
