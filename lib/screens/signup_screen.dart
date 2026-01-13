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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -50,
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
                        "KATIL",
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      child: Text(
                        "MACERAYA BAŞLAMAK ÜZERESİN",
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Signup Form
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          _AuthInput(controller: _emailController, hint: 'E-POSTA ADRESİ', icon: Icons.alternate_email_rounded),
                          const SizedBox(height: 16),
                          _AuthInput(controller: _passwordController, hint: 'ŞİFRE', icon: Icons.lock_outline_rounded, isPassword: true),
                          const SizedBox(height: 16),
                          _AuthInput(controller: _confirmPasswordController, hint: 'ŞİFREYİ ONAYLA', icon: Icons.lock_clock_outlined, isPassword: true),
                          const SizedBox(height: 32),
                          
                          if (_isLoading)
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            ElevatedButton(
                              onPressed: _signup,
                              child: const Text('KAYIT OL'),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Social Login
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              icon: 'assets/google_logo.png', 
                              onTap: _googleLogin,
                              isAsset: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SocialButton(
                              iconPath: Icons.phone_iphone_rounded, 
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen())),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Login Link
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("ZATEN HESABINIZ VAR MI?", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: const Text("GİRİŞ YAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        backgroundColor: const Color(0xFF0A0A0A),
        minimumSize: const Size.fromHeight(60),
      ),
      child: isAsset 
        ? Image.asset(icon, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, color: Colors.white))
        : Icon(iconPath, color: Colors.white, size: 20),
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
