import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead; // YENİ: Okundu mu bilgisi

  Message({
    this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false, // Varsayılan: Okunmadı
  });

  factory Message.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'],
      imageUrl: data['imageUrl'],
      isRead: data['isRead'] ?? false, // Veritabanından oku
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'isRead': isRead, // Kaydet
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String vehicleTitle;
  final String vehicleImage;

  ChatRoom({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.vehicleTitle,
    required this.vehicleImage,
  });

  factory ChatRoom.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vehicleTitle: data['vehicleTitle'] ?? '',
      vehicleImage: data['vehicleImage'] ?? '',
    );
  }
}
