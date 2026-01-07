import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/screens/login_screen.dart';
import 'package:rentgo/screens/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, snapshot) {
        // Yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmışsa ana ekranı göster
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Kullanıcı giriş yapmamışsa giriş ekranını göster
        return const LoginScreen();
      },
    );
  }
}
