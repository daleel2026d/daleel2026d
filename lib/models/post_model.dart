import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/content_sanitizer.dart';

class Post {
  final String title;
  final String description;
  final String imageUrl;
  final String date;

  Post({
    required this.title,
    required this.description,
    this.imageUrl = '',
    required this.date,
  });

  factory Post.fromMap(Map<String, dynamic> data) {
    final imageUrl = ContentSanitizer.sanitizeImageUrl(
      data['imageUrl'] ?? data['image'] ?? data['image_url'] ?? '',
    );
    final rawDate = data['date'];
    String date = '';
    if (rawDate != null) {
      if (rawDate is Timestamp) {
        date = rawDate.toDate().toIso8601String();
      } else {
        date = rawDate.toString();
      }
    }
    return Post(
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: imageUrl,
      date: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': date,
    };
  }
}
