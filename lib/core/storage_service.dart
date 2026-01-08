import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // İlan resimlerini toplu halde yükler
  Future<List<String>> uploadVehicleImages(List<File> files) async {
    try {
      final List<Future<String>> uploadTasks = files.map((file) async {
        final String fileName = const Uuid().v4();
        final Reference ref = _storage.ref().child('vehicle_images/$fileName');
        final UploadTask uploadTask = ref.putFile(file);
        final TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }).toList();

      final List<String> downloadUrls = await Future.wait(uploadTasks);
      return downloadUrls;
    } on FirebaseException catch (e) {
      print('İlan resimleri yüklenirken hata: $e');
      rethrow;
    }
  }

  // Profil resmini yükler
  Future<String> uploadProfileImage(File file, String userId) async {
    try {
      // Kullanıcıya özel ve sabit bir dosya adı kullan (eskiyi üzerine yazmak için)
      final Reference ref = _storage.ref().child('profile_images/$userId');
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print('Profil resmi yüklenirken hata: $e');
      rethrow;
    }
  }

  // Bir resmi URL'sinden sil
  Future<void> deleteImageFromUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        print('Resim silinirken hata oluştu: $e');
        rethrow;
      }
    }
  }
}
