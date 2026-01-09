import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pendingDelivery, // Aracı teslim etme aşaması (Haritandaki 4. adım)
  delivered,       // Araç sahibi teslim etti (5. adım)
  completed,       // Müşteri teslim aldı ve onayladı (6. adım)
  cancelled        // İptal edildi
}

class Booking {
  final String? id;
  final String vehicleId;
  final String vehicleTitle;
  final String? vehicleImage;
  final String ownerId;
  final String customerId;
  final String customerName;
  final int days;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;

  Booking({
    this.id,
    required this.vehicleId,
    required this.vehicleTitle,
    this.vehicleImage,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    required this.days,
    required this.totalPrice,
    this.status = BookingStatus.pendingDelivery,
    required this.createdAt,
  });

  // Firestore'dan gelen veriyi modele çevir
  factory Booking.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      vehicleId: data['vehicleId'] ?? '',
      vehicleTitle: data['vehicleTitle'] ?? '',
      vehicleImage: data['vehicleImage'],
      ownerId: data['ownerId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      days: data['days'] ?? 1,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => BookingStatus.pendingDelivery,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Modeli Firestore'a kaydedilecek haritaya çevir
  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'vehicleTitle': vehicleTitle,
      'vehicleImage': vehicleImage,
      'ownerId': ownerId,
      'customerId': customerId,
      'customerName': customerName,
      'days': days,
      'totalPrice': totalPrice,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
