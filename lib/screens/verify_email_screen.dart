import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  Timer? timer;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      // Her 3 saniyede bir kullanıcının onay durumunu kontrol et
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  Future<void> checkEmailVerified() async {
    // Kullanıcı durumunu Firebase'den yeniden yükle
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      timer?.cancel();
      // AuthGate, değişikliği zaten dinlediği için yönlendirme otomatik olacak.
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E-posta Onayı"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hesabınızı doğrulamak için bir onay linki e-posta adresinize gönderildi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.email_outlined, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Lütfen gelen kutunuzu kontrol edin ve linke tıklayın. Onayladığınızda uygulama otomatik olarak devam edecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.send),
              label: const Text('Onay Mailini Tekrar Gönder'),
              onPressed: () {
                try {
                  FirebaseAuth.instance.currentUser!.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeni bir onay maili gönderildi.')),
                  );
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mail gönderilemedi: ${e.toString()}')),
                  );
                }
              },
            ),
            TextButton(
              onPressed: () => _authService.signOut(),
              child: const Text('İptal Et / Çıkış Yap', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
