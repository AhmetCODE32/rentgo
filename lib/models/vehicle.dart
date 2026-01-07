import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String? id;
  final String userId;
  final String title;
  final String city;
  final String price;
  final bool isCar;
  final List<String> images; // List<File> yerine List<String> (URL'ler için)

  Vehicle({
    this.id,
    required this.userId,
    required this.title,
    required this.city,
    required this.price,
    required this.isCar,
    this.images = const [], // Varsayılan olarak boş liste
  });

  // Firestore'a göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'city': city,
      'price': price,
      'isCar': isCar,
      'images': images,
      'createdAt': FieldValue.serverTimestamp(), // EKLENDİ: İlanın oluşturulma zamanı
    };
  }

  // Firestore'dan gelen Map'i Vehicle nesnesine dönüştürme
  factory Vehicle.fromMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Vehicle(
      id: doc.id, // Döküman ID'sini al
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      city: map['city'] ?? '',
      price: map['price'] ?? '',
      isCar: map['isCar'] ?? true,
      images: List<String>.from(map['images'] ?? []),
    );
  }
}
