import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'gpa_match', 'favorite_update', 'new_scholarship', 'new_post', 'general'
  final String targetType; // 'university', 'scholarship', 'opportunity', 'training_center', 'general'
  final String targetId;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetType = 'general',
    this.targetId = '',
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    DateTime createdAt = DateTime.now();
    final rawDate = data['createdAt'];
    if (rawDate != null) {
      if (rawDate is Timestamp) {
        createdAt = rawDate.toDate();
      } else if (rawDate is String) {
        createdAt = DateTime.tryParse(rawDate) ?? DateTime.now();
      }
    }

    return AppNotification(
      id: id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      type: data['type']?.toString() ?? 'general',
      targetType: data['targetType']?.toString() ?? 'general',
      targetId: data['targetId']?.toString() ?? '',
      createdAt: createdAt,
      isRead: data['isRead'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetType': targetType,
      'targetId': targetId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? targetType,
    String? targetId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
