import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/screens/login_screen.dart';
import 'package:rentgo/screens/main_screen.dart';
import 'package:rentgo/screens/verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmış mı?
        if (snapshot.hasData) {
          // E-postası onaylı mı?
          if (snapshot.data!.emailVerified) {
            return const MainScreen(); // Onaylıysa ana ekran
          } else {
            return const VerifyEmailScreen(); // Onaylı değilse bekleme odası
          }
        }

        // Kullanıcı giriş yapmamışsa giriş ekranını göster
        return const LoginScreen();
      },
    );
  }
}
