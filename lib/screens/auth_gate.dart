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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white24),
            ),
          );
        }

        if (snapshot.hasData) {
          // GOOGLE VEYA TELEFON GİRİŞİNDE E-POSTA ONAYINA BAKMA
          final user = snapshot.data!;
          bool isSocialLogin = user.providerData.any((p) => p.providerId == 'google.com' || p.providerId == 'phone');
          
          if (user.emailVerified || isSocialLogin) {
            return const MainScreen();
          } else {
            return const VerifyEmailScreen();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
