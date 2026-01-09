import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentgo/core/storage_service.dart';
import '../models/vehicle.dart';
import '../models/booking.dart';
import '../models/message.dart';
import '../models/review.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  late final CollectionReference<Vehicle> _vehiclesRef;
  late final CollectionReference<Map<String, dynamic>> _usersRef;
  late final CollectionReference<Map<String, dynamic>> _reportsRef;
  late final CollectionReference<Booking> _bookingsRef;
  late final CollectionReference<Map<String, dynamic>> _chatsRef;
  late final CollectionReference<Review> _reviewsRef;

  FirestoreService() {
    _vehiclesRef = _db.collection('vehicles').withConverter<Vehicle>(
          fromFirestore: (snapshot, _) => Vehicle.fromMap(snapshot),
          toFirestore: (vehicle, _) => vehicle.toMap(),
        );
    _usersRef = _db.collection('users');
    _reportsRef = _db.collection('reports');
    _bookingsRef = _db.collection('bookings').withConverter<Booking>(
          fromFirestore: (snapshot, _) => Booking.fromMap(snapshot),
          toFirestore: (booking, _) => booking.toMap(),
        );
    _chatsRef = _db.collection('chats');
    _reviewsRef = _db.collection('reviews').withConverter<Review>(
          fromFirestore: (snapshot, _) => Review.fromMap(snapshot),
          toFirestore: (review, _) => review.toMap(),
        );
  }

  // --- CANLI TAKİP METOTLARI (YENİ) ---

  // Kullanıcının çevrimiçi durumunu güncelle
  Future<void> updateUserStatus(String uid, bool isOnline) {
    return _usersRef.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    final messages = await _chatsRef
        .doc(roomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // --- FAVORİ METOTLARI ---
  Future<void> toggleFavorite(String userId, String vehicleId) async {
    final favRef = _usersRef.doc(userId).collection('favorites').doc(vehicleId);
    final doc = await favRef.get();
    if (doc.exists) { await favRef.delete(); } else { await favRef.set({'vehicleId': vehicleId, 'addedAt': FieldValue.serverTimestamp()}); }
  }

  Stream<bool> isFavoriteStream(String userId, String vehicleId) => _usersRef.doc(userId).collection('favorites').doc(vehicleId).snapshots().map((doc) => doc.exists);
  Stream<List<String>> getFavoriteVehicleIds(String userId) => _usersRef.doc(userId).collection('favorites').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());

  // --- USER PROFILE METHODS ---
  Future<void> createUserProfile(User user) {
    return _usersRef.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı',
      'photoURL': user.photoURL,
      'bio': '',
      'city': 'Kilis',
      'isPhoneVerified': user.phoneNumber != null && user.phoneNumber!.isNotEmpty,
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) => _usersRef.doc(uid).snapshots();

  Future<void> updateUserProfile(String uid, {String? displayName, String? photoURL, String? bio, String? city, bool? isPhoneVerified}) {
    final Map<String, dynamic> dataToUpdate = {};
    if (displayName != null) dataToUpdate['displayName'] = displayName;
    if (photoURL != null) dataToUpdate['photoURL'] = photoURL;
    if (bio != null) dataToUpdate['bio'] = bio;
    if (city != null) dataToUpdate['city'] = city;
    if (isPhoneVerified != null) dataToUpdate['isPhoneVerified'] = isPhoneVerified;
    if (dataToUpdate.isNotEmpty) return _usersRef.doc(uid).update(dataToUpdate);
    return Future.value();
  }

  // --- REVIEW METHODS ---
  Future<void> addReview(Review review) async => await _reviewsRef.add(review);
  Stream<QuerySnapshot<Review>> getUserReviews(String userId) => _reviewsRef.where('targetUserId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();

  // --- CHAT METHODS ---
  Future<void> sendMessage({
    required String roomId,
    required String vehicleId,
    required String vehicleTitle,
    required String vehicleImage,
    required String ownerId,
    required String customerId,
    required String text,
    required String senderId,
    String? imageUrl,
  }) async {
    await _chatsRef.doc(roomId).set({
      'users': FieldValue.arrayUnion([ownerId, customerId]),
      'lastMessage': text ?? 'Resim gönderildi',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'vehicleTitle': vehicleTitle,
      'vehicleImage': vehicleImage,
      'vehicleId': vehicleId,
    }, SetOptions(merge: true));

    await _chatsRef.doc(roomId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'isRead': false, // YENİ MESAJ OKUNMADI
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatRooms(String userId) => _chatsRef.where('users', arrayContains: userId).orderBy('lastMessageTime', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String roomId) => _chatsRef.doc(roomId).collection('messages').orderBy('createdAt', descending: true).snapshots();

  // --- VEHICLE METHODS ---
  Stream<QuerySnapshot<Vehicle>> getVehiclesStream() => _vehiclesRef.orderBy('createdAt', descending: true).snapshots();
  Future<void> addVehicle(Vehicle vehicle) => _vehiclesRef.add(vehicle);
  Future<void> updateVehicle(String vehicleId, Map<String, dynamic> data) => _vehiclesRef.doc(vehicleId).update(data);
  Future<void> deleteVehicle(String vehicleId) async {
    final doc = await _vehiclesRef.doc(vehicleId).get();
    final vehicle = doc.data();
    if (vehicle != null) { for (var url in vehicle.images) { await _storageService.deleteImageFromUrl(url); } }
    await _vehiclesRef.doc(vehicleId).delete();
  }

  // --- BOOKING METHODS ---
  Future<void> createBooking(Booking booking) => _bookingsRef.add(booking);
  Stream<QuerySnapshot<Booking>> getCustomerBookings(String userId) => _bookingsRef.where('customerId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Booking>> getOwnerBookings(String userId) => _bookingsRef.where('ownerId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) => _bookingsRef.doc(bookingId).update({'status': status.toString()});

  // --- REPORT METHOD ---
  Future<void> reportVehicle({required String vehicleId, required String reporterId, required String reason, required String details}) => _reportsRef.add({'vehicleId': vehicleId, 'reporterId': reporterId, 'reason': reason, 'details': details, 'createdAt': FieldValue.serverTimestamp(), 'status': 'pending'});
}
