import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // --- İLAN RESİMLERİ YÜKLEME ---
  Future<List<String>> uploadVehicleImages(List<File> images) async {
    List<String> urls = [];
    for (var image in images) {
      String fileName = _uuid.v4();
      Reference ref = _storage.ref().child('vehicle_images').child(fileName);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // --- PROFİL RESMİ YÜKLEME ---
  Future<String> uploadProfileImage(File image, String uid) async {
    Reference ref = _storage.ref().child('profile_images').child('$uid.jpg');
    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // --- CHAT RESMİ YÜKLEME (YENİ) ---
  Future<String> uploadChatImage(File image) async {
    String fileName = 'chat_${_uuid.v4()}.jpg';
    Reference ref = _storage.ref().child('chat_images').child(fileName);
    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // --- RESİM SİLME ---
  Future<void> deleteImageFromUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      print('Resim silinirken hata (Dosya zaten silinmiş olabilir): $e');
    }
  }
}
