import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? id;
  final String reviewerId; // Yorumu yapan
  final String reviewerName;
  final String targetUserId; // Yorum yapılan (Satıcı)
  final String bookingId; // Hangi işlem için
  final double rating; // 1-5 arası yıldız
  final String comment;
  final DateTime createdAt;

  Review({
    this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.targetUserId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Anonim',
      targetUserId: data['targetUserId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'targetUserId': targetUserId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
