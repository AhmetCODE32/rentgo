import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentgo/core/storage_service.dart';
import '../models/vehicle.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService(); // Storage servisi eklendi

  late final CollectionReference<Vehicle> _vehiclesRef;
  late final CollectionReference<Map<String, dynamic>> _usersRef;

  FirestoreService() {
    _vehiclesRef = _db.collection('vehicles').withConverter<Vehicle>(
          fromFirestore: (snapshot, _) => Vehicle.fromMap(snapshot),
          toFirestore: (vehicle, _) => vehicle.toMap(),
        );
    _usersRef = _db.collection('users');
  }

  // --- Vehicle Methods ---
  Stream<QuerySnapshot<Vehicle>> getVehiclesStream() {
    return _vehiclesRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addVehicle(Vehicle vehicle) {
    return _vehiclesRef.add(vehicle);
  }

  // YENİ VE GÜVENLİ SİLME METODU
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      // 1. Önce silinecek ilanın belgesini al
      final doc = await _vehiclesRef.doc(vehicleId).get();
      final vehicle = doc.data();

      if (vehicle != null) {
        // 2. İlanın resim URL'lerini kullanarak Storage'dan resimleri sil
        final deleteImageFutures = vehicle.images.map((url) => _storageService.deleteImageFromUrl(url));
        await Future.wait(deleteImageFutures); // Tüm silme işlemlerinin bitmesini bekle
      }

      // 3. Resimler silindikten sonra Firestore belgesini sil
      await _vehiclesRef.doc(vehicleId).delete();
    } catch (e) {
      print('İlan silinirken bir hata oluştu: $e');
      rethrow;
    }
  }

  // --- User Profile Methods ---
  Future<void> createUserProfile(User user) {
    return _usersRef.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı',
      'photoURL': user.photoURL,
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _usersRef.doc(uid).snapshots();
  }

  Future<void> updateUserProfile(String uid, {String? displayName, String? photoURL}) {
    final Map<String, dynamic> dataToUpdate = {};
    if (displayName != null) dataToUpdate['displayName'] = displayName;
    if (photoURL != null) dataToUpdate['photoURL'] = photoURL;

    if (dataToUpdate.isNotEmpty) {
      return _usersRef.doc(uid).update(dataToUpdate);
    }
    return Future.value();
  }
}
