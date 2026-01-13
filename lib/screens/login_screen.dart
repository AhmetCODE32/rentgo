import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }
    await _performAuthAction(() => _authService.signInWithEmailAndPassword(_emailController.text.trim(), _passwordController.text.trim()));
  }

  Future<void> _loginWithGoogle() async {
    await _performAuthAction(() => _authService.signInWithGoogle());
  }

  Future<void> _performAuthAction(Future<User?> Function() authAction) async {
    setState(() => _isLoading = true);
    try {
      final user = await authAction();
      if (mounted && user != null && !user.emailVerified && user.providerData.any((p) => p.providerId == 'password')) {
        _showError('Lütfen e-postanızı doğrulayın.');
        await _authService.signOut();
      }
    } catch (e) {
      _showError('Giriş başarısız oldu.');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: const Text(
                        "VROOMY",
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      child: Text(
                        "PRESTİJLİ SÜRÜŞÜN ADRESİ",
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Login Form
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          _AuthInput(controller: _emailController, hint: 'E-POSTA ADRESİ', icon: Icons.alternate_email_rounded),
                          const SizedBox(height: 16),
                          _AuthInput(controller: _passwordController, hint: 'ŞİFRE', icon: Icons.lock_outline_rounded, isPassword: true),
                          const SizedBox(height: 32),
                          
                          if (_isLoading)
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            ElevatedButton(
                              onPressed: _loginWithEmail,
                              child: const Text('GİRİŞ YAP'),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Social Login Divider
                    FadeIn(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("VEYA", style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Google Login Button
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: OutlinedButton(
                        onPressed: _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          backgroundColor: const Color(0xFF0A0A0A),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google_logo.png', height: 20, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, color: Colors.white)),
                            const SizedBox(width: 12),
                            const Text('GOOGLE İLE DEVAM ET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Sign Up Link
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("HESABINIZ YOK MU?", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                            child: const Text("KAYIT OL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
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

class _AuthInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final bool isPassword;
  const _AuthInput({required this.controller, required this.hint, required this.icon, this.isPassword = false});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.2), size: 20),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.03))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}
