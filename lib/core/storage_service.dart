import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Resmi Firebase Storage'a yükle ve indirme URL'sini döndür
  Future<String> uploadImage(File file) async {
    try {
      // Benzersiz bir dosya adı oluştur (çakışmaları önlemek için)
      final String fileName = const Uuid().v4();
      final Reference ref = _storage.ref().child('vehicle_images/$fileName');

      // Dosyayı yükle
      final UploadTask uploadTask = ref.putFile(file);

      // Yükleme tamamlandığında URL'i al
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      // Hata yönetimi
      print(e);
      rethrow; // Hatanın üst katmana bildirilmesi için yeniden fırlat
    }
  }
}
