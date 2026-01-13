import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  message,
  booking,
  system,
  premium
}

class AppNotification {
  final String? id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final String? relatedId; // ChatId veya BookingId gibi

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'type': type.toString(),
      'relatedId': relatedId,
    };
  }

  factory AppNotification.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.system,
      ),
      relatedId: data['relatedId'],
    );
  }
}
