import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı oturum durumunu dinleyen stream
  Stream<User?> get user => _auth.authStateChanges();

  // E-posta ve şifre ile kayıt olma ve ONAY MAİLİ GÖNDERME
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Kullanıcı oluşturulduktan hemen sonra onay maili gönder
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // E-posta ve şifre ile giriş yapma
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
