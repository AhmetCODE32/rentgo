import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> deleteVehicle(String vehicleId) {
    return _vehiclesRef.doc(vehicleId).delete();
  }

  // --- User Profile Methods ---

  // Yeni kullanıcı için veritabanında bir döküman oluşturur
  Future<void> createUserProfile(User user) {
    return _usersRef.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı',
      'photoURL': user.photoURL,
    }, SetOptions(merge: true)); // Eğer veri varsa üzerine yazma, birleştir
  }

  // Belirli bir kullanıcının profilini dinleyen stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _usersRef.doc(uid).snapshots();
  }

  // Kullanıcı profilini güncelle
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
