import 'dart:ui';
import 'package:animate_do/animate_do.dart';
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
      _showError('Lütfen geçerli bir telefon numarası girin.');
      return;
    }

    setState(() => _isLoading = true);
    final fullPhoneNumber = '+90$phone';

    await _authService.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      verificationCompleted: (credential) {},
      verificationFailed: (e) {
        if(mounted) {
          setState(() => _isLoading = false);
          _showError('Doğrulama başarısız: ${e.message}');
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        if(mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => OTPScreen(verificationId: verificationId, phoneNumber: fullPhoneNumber)));
          setState(() => _isLoading = false);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: Stack(
        children: [
          // 1. ŞIK GRADYAN ARKA PLAN
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF1E1B4B)],
              ),
            ),
          ),
          
          Positioned(top: -50, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.blueAccent.withAlpha(15), shape: BoxShape.circle))),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2. MODERN LOGO
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent.withAlpha(30)),
                        ),
                        child: Icon(Icons.phone_iphone_rounded, color: Colors.blueAccent, size: size.height * 0.07),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    FadeInUp(child: const Text("Telefonla Giriş", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(height: 12),
                    FadeInUp(delay: const Duration(milliseconds: 200), child: Text("Onay kodu SMS olarak gönderilecektir.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14))),
                    
                    const SizedBox(height: 50),

                    // 3. CAM EFEKTLİ GİRİŞ ALANI
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withAlpha(10)),
                          ),
                          child: Column(
                            children: [
                              _AuthInput(controller: _phoneController, hint: '5XX XXX XX XX', icon: Icons.phone_android_rounded),
                              const SizedBox(height: 32),
                              
                              if (_isLoading)
                                const CircularProgressIndicator(color: Colors.blueAccent)
                              else
                                ElevatedButton(
                                  onPressed: _sendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shadowColor: Colors.blueAccent.withAlpha(100),
                                    elevation: 10,
                                  ),
                                  child: const Text('Kodu Gönder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon;
  const _AuthInput({required this.controller, required this.hint, required this.icon});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(40), fontSize: 16, letterSpacing: 1),
        prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.phone, color: Colors.blueAccent, size: 20), SizedBox(width: 8), Text("+90 ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
