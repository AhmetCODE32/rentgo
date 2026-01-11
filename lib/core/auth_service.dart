import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rentgo/core/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get user => _auth.authStateChanges();

  // --- TELEFON İLE DOĞRULAMA (MEVCUT HESABA BAĞLAMA) ---
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Otomatik doğrulama olursa hesaba bağla
        final user = _auth.currentUser;
        if (user != null) {
          await user.linkWithCredential(credential);
          await _firestoreService.updateUserProfile(user.uid, isPhoneVerified: true);
        }
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User?> verifyAndLinkSmsCode(String verificationId, String smsCode) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    
    // MEVCUT HESABI TELEFONLA MÜHÜRLE (Link)
    final result = await user.linkWithCredential(credential);
    final updatedUser = result.user;
    
    if (updatedUser != null) {
      await _firestoreService.updateUserProfile(updatedUser.uid, isPhoneVerified: true);
    }
    return updatedUser;
  }

  // --- TELEFON İLE GİRİŞ (ESKİ METOTLAR) ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<User?> signInWithSmsCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null && (userCredential.additionalUserInfo?.isNewUser ?? false)) {
      await _firestoreService.createUserProfile(user);
    }
    return user;
  }

  // --- DİĞER METOTLAR ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null && (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        await _firestoreService.createUserProfile(user);
      }
      return user;
    } catch (e) {
      print(e);
      throw Exception('Google ile giriş yaparken bir hata oluştu.');
    }
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final User? user = result.user;
      if (user != null) {
        await _firestoreService.createUserProfile(user);
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
