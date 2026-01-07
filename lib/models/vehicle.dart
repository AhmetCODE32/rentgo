import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType { rent, sale }

class Vehicle {
  final String? id;
  final String userId;
  final String sellerName; // YENİ
  final String phoneNumber; // YENİ
  final String title;
  final String description;
  final String city;
  final String pickupAddress; // YENİ
  final double price;
  final bool isCar;
  final ListingType listingType;
  final List<String> images;
  final Map<String, dynamic> specs;

  Vehicle({
    this.id,
    required this.userId,
    required this.sellerName,
    required this.phoneNumber,
    required this.title,
    required this.description,
    required this.city,
    required this.pickupAddress,
    required this.price,
    required this.isCar,
    required this.listingType,
    this.images = const [],
    this.specs = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sellerName': sellerName,
      'phoneNumber': phoneNumber,
      'title': title,
      'description': description,
      'city': city,
      'pickupAddress': pickupAddress,
      'price': price,
      'isCar': isCar,
      'listingType': listingType.name,
      'images': images,
      'specs': specs,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Vehicle.fromMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Vehicle(
      id: doc.id,
      userId: map['userId'] ?? '',
      sellerName: map['sellerName'] ?? 'Belirtilmemiş',
      phoneNumber: map['phoneNumber'] ?? 'Belirtilmemiş',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      city: map['city'] ?? '',
      pickupAddress: map['pickupAddress'] ?? 'Belirtilmemiş',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isCar: map['isCar'] ?? true,
      listingType: ListingType.values.firstWhere(
        (e) => e.name == map['listingType'],
        orElse: () => ListingType.rent,
      ),
      images: List<String>.from(map['images'] ?? []),
      specs: Map<String, dynamic>.from(map['specs'] ?? {}),
    );
  }
}
