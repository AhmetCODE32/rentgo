import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Araç koleksiyonuna referans
  late final CollectionReference<Vehicle> _vehiclesRef;

  FirestoreService() {
    _vehiclesRef = _db.collection('vehicles').withConverter<Vehicle>(
          fromFirestore: (snapshot, _) => Vehicle.fromMap(snapshot),
          toFirestore: (vehicle, _) => vehicle.toMap(),
        );
  }

  // Tüm araçları dinleyen stream
  Stream<QuerySnapshot<Vehicle>> getVehiclesStream() {
    return _vehiclesRef.orderBy('createdAt', descending: true).snapshots();
  }

  // Yeni araç ekleme
  Future<void> addVehicle(Vehicle vehicle) {
    return _vehiclesRef.add(vehicle);
  }

  // (Gelecekte buraya aracı silme, güncelleme gibi metotlar da eklenebilir)
}
