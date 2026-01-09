import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/screens/login_screen.dart';
import 'package:rentgo/screens/phone_auth_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Şifreler eşleşmiyor.');
      return;
    }
    await _performAuthAction(() => _authService.signUpWithEmailAndPassword(_emailController.text.trim(), _passwordController.text.trim()));
  }

  Future<void> _googleLogin() async {
    await _performAuthAction(() => _authService.signInWithGoogle());
  }

  Future<void> _performAuthAction(Future<User?> Function() authAction) async {
    setState(() => _isLoading = true);
    try {
      await authAction();
    } catch (e) {
      _showError('Kayıt başarısız oldu.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. PREMIUM GRADYAN ARKA PLAN
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
                        child: Icon(Icons.person_add_alt_1_rounded, color: Colors.blueAccent, size: size.height * 0.07),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    FadeInUp(
                      child: const Text(
                        "Yeni Hesap",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        "Maceraya katılmaya hazır mısın?",
                        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 3. CAM EFEKTLİ GİRİŞ ALANLARI
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
                              _AuthInput(controller: _emailController, hint: 'E-posta Adresi', icon: Icons.alternate_email_rounded),
                              const SizedBox(height: 16),
                              _AuthInput(controller: _passwordController, hint: 'Şifre', icon: Icons.lock_outline_rounded, isPassword: true),
                              const SizedBox(height: 16),
                              _AuthInput(controller: _confirmPasswordController, hint: 'Şifreyi Onayla', icon: Icons.lock_clock_outlined, isPassword: true),
                              const SizedBox(height: 32),
                              
                              if (_isLoading)
                                const CircularProgressIndicator(color: Colors.blueAccent)
                              else
                                ElevatedButton(
                                  onPressed: _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shadowColor: Colors.blueAccent.withAlpha(100),
                                    elevation: 10,
                                  ),
                                  child: const Text('Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            icon: 'assets/google_logo.png', 
                            onTap: _googleLogin,
                            isAsset: true,
                          ),
                          const SizedBox(width: 20),
                          _SocialButton(
                            iconPath: Icons.phone_iphone_rounded, 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen())),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Zaten bir hesabın var mı?", style: TextStyle(color: Colors.white.withAlpha(100))),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: const Text("Giriş Yap", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
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

class _SocialButton extends StatelessWidget {
  final dynamic icon; final IconData? iconPath; final VoidCallback onTap; final bool isAsset;
  const _SocialButton({this.icon, this.iconPath, required this.onTap, this.isAsset = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(10))),
        child: isAsset 
          ? Image.asset(icon, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 24))
          : Icon(iconPath, color: Colors.white, size: 24),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final bool isPassword;
  const _AuthInput({required this.controller, required this.hint, required this.icon, this.isPassword = false});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(40)),
        prefixIcon: Icon(icon, color: Colors.blueAccent.withAlpha(150), size: 20),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
