import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/screens/otp_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir telefon numarası girin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ÖNEMLİ: Türkiye için ülke kodunu (+90) otomatik ekliyoruz.
    // Kullanıcının +90 ile başlamasına gerek yok.
    final fullPhoneNumber = '+90$phone';

    await _authService.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      verificationCompleted: (credential) {
        // Bu nadiren çalışır, genellikle otomatik doğrulamada
      },
      verificationFailed: (e) {
        if(mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Doğrulama başarısız: ${e.message}')),
          );
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        if(mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(verificationId: verificationId, phoneNumber: fullPhoneNumber),
            ),
          );
           setState(() => _isLoading = false);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telefonla Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Telefon Numaranız',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Size bir doğrulama kodu göndereceğiz.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                prefixText: '+90 ',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kodu Gönder'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
