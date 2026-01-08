import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
      _showError('İşlem başarısız oldu: ${e.toString()}');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(duration: const Duration(milliseconds: 800), child: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent, size: 80)),
                  const SizedBox(height: 24),
                  FadeInUp(delay: const Duration(milliseconds: 200), child: Text('Yeni Hesap Oluştur', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  FadeInUp(delay: const Duration(milliseconds: 300), child: const Text('Maceraya katılın!', style: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 40),
                  FadeInUp(delay: const Duration(milliseconds: 400), child: _AuthInput(controller: _emailController, hint: 'E-posta', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
                  const SizedBox(height: 16),
                  FadeInUp(delay: const Duration(milliseconds: 500), child: _AuthInput(controller: _passwordController, hint: 'Şifre', icon: Icons.lock_outline, isPassword: true)),
                  const SizedBox(height: 16),
                  FadeInUp(delay: const Duration(milliseconds: 600), child: _AuthInput(controller: _confirmPasswordController, hint: 'Şifreyi Onayla', icon: Icons.lock_clock_outlined, isPassword: true)),
                  const SizedBox(height: 32),
                  if (_isLoading) const CircularProgressIndicator(),
                  if (!_isLoading)
                    FadeInUp(
                      delay: const Duration(milliseconds: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(onPressed: _signup, child: const Text('Kayıt Ol')),
                          const SizedBox(height: 24),
                          const Row(children: [Expanded(child: Divider(color: Colors.white24)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('VEYA', style: TextStyle(color: Colors.grey))), Expanded(child: Divider(color: Colors.white24))]),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(icon: Image.asset('assets/google_logo.png', height: 22), label: const Text('Google ile Devam Et'), onPressed: _googleLogin),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(icon: const Icon(Icons.phone_iphone), label: const Text('Telefon Numarası ile Devam Et'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen()))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (!_isLoading) FadeInUp(delay: const Duration(milliseconds: 800), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Zaten bir hesabınız var mı?', style: TextStyle(color: Colors.grey)), TextButton(onPressed: () => Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const LoginScreen(), transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child))), child: const Text('Giriş Yapın'))])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final bool isPassword; final TextInputType keyboardType;
  const _AuthInput({super.key, required this.controller, required this.hint, required this.icon, this.isPassword = false, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller, keyboardType: keyboardType, obscureText: isPassword, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)));
  }
}
