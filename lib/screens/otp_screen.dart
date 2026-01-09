import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/screens/main_screen.dart'; // DÜZELTİLDİ: Artık MainScreen kullanıyoruz

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length < 6) {
      _showError('Lütfen 6 haneli onay kodunu girin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithSmsCode(widget.verificationId, code);
      if (mounted && user != null) {
        // BAŞARILI: Ana ekrana pırlanta gibi geçiş yap
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Geçersiz kod. Lütfen tekrar deneyin.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    _otpController.dispose();
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF1E1B4B)],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent.withAlpha(30)),
                        ),
                        child: Icon(Icons.mark_email_read_rounded, color: Colors.blueAccent, size: size.height * 0.07),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    FadeInUp(child: const Text("Kodu Doğrula", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200), 
                      child: Text(
                        "${widget.phoneNumber} numarasına gönderilen 6 haneli kodu girin.", 
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14)
                      )
                    ),
                    
                    const SizedBox(height: 50),

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
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
                                maxLength: 6,
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: "000000",
                                  hintStyle: TextStyle(color: Colors.white.withAlpha(20), letterSpacing: 8),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              if (_isLoading)
                                const CircularProgressIndicator(color: Colors.blueAccent)
                              else
                                ElevatedButton(
                                  onPressed: _verifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shadowColor: Colors.blueAccent.withAlpha(100),
                                    elevation: 10,
                                  ),
                                  child: const Text('Doğrula ve Başla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Numarayı Değiştir", style: TextStyle(color: Colors.white.withAlpha(100))),
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
